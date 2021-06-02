import Vapor
import Fluent

/// Enables OAuth-2 tasks.
public protocol OAuthable {
    /// Convenience typealias for the type representing
    /// the policy to encode query parameters with.
    typealias Policy = QueryParametersPolicy
    
    /// Scopes that the app can get permissions to access.
    /// An enum conforming to `String` and `CaseIterable` is the best way.
    associatedtype Scopes: CaseIterable & RawRepresentable
    where Scopes.RawValue == String
    
    /// Your client id, acquired after registering your app in your provider's panel.
    var clientId: String { get }
    
    /// Your client secret, acquired after registering your app in your provider's panel.
    var clientSecret: String { get }
    
    /// Your callback url.
    /// Must be registered as one of the callback urls in your provider's panel.
    var callbackUrl: String { get }
    
    /// Provider's endpoint that you redirect users to,
    /// so they are asked to give permissions to this app.
    var providerAuthorizationUrl: String { get }
    
    /// After getting a `code` from the provider when a user has given permissions to this app,
    /// The `code` is passed to this url and in return, an `access token` is acquired.
    var providerTokenUrl: String { get }
    
    /// The policy to encode query parameters with.
    var queryParametersPolicy: Policy { get }
    
    /// The provider which issues these tokens.
    var issuer: Issuer { get }
}

//MARK: Default-Value extension
extension OAuthable {
    var queryParametersPolicy: Policy { .default }
}

//MARK: - Internal Declarations

internal extension OAuthable {
    
    /// The url to redirect user to,
    /// so they are asked to give this app permissions to access their data.
    /// - Throws: OAuthableError in case of error.
    func authorizationRedirectUrl(
        state: String = .random(length: 64),
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            response_type: "code",
            redirect_uri: self.callbackUrl,
            scope: scopes.map(\.rawValue).joined(separator: " "),
            state: state)
        let redirectUrl = self.providerAuthorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// The request that gets an access token from the provider,
    /// using the `code` that this app should acquired after
    /// user being redirected to this app by the provider.
    /// - Throws: OAuthableError in case of error.
    func getUserAccessTokenRequest(code: String) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            client_secret: self.clientSecret,
            redirect_uri: self.callbackUrl,
            grant_type: "authorization_code",
            code: code)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.providerTokenUrl)
        
        let queryParametersEncode: Void? = try? self.queryParametersPolicy
            .inject(parameters: queryParams, into: &clientRequest)
        guard queryParametersEncode != nil else {
            throw OAuthableError.serverError(
                status: .preconditionFailed,
                error: .queryParametersEncode(policy: queryParametersPolicy)
            )
        }
        
        return clientRequest
    }
    
    /// The request to refresh an expired token with.
    /// - Throws: OAuthableError in case of error.
    func refreshTokenRequest(refreshToken: String) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            client_secret: self.clientSecret,
            grant_type: "refresh_token",
            refresh_token: refreshToken)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.providerTokenUrl)
        
        let queryParametersEncode: Void? = try? self.queryParametersPolicy
            .inject(parameters: queryParams, into: &clientRequest)
        guard queryParametersEncode != nil else {
            throw OAuthableError.serverError(
                status: .preconditionFailed,
                error: .queryParametersEncode(policy: queryParametersPolicy)
            )
        }
        
        return clientRequest
    }
    
    /// The request to acquire an app access token.
    /// - Throws: OAuthableError in case of error.
    func getAppAccessTokenRequest() throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            client_secret: self.clientSecret,
            grant_type: "client_credentials")
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.providerTokenUrl)
        
        let queryParametersEncode: Void? = try? self.queryParametersPolicy
            .inject(parameters: queryParams, into: &clientRequest)
        guard queryParametersEncode != nil else {
            throw OAuthableError.serverError(
                status: .preconditionFailed,
                error: .queryParametersEncode(policy: queryParametersPolicy)
            )
        }
        
        return clientRequest
    }
    
    /// Immediately tries to refresh the token.
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    func renewToken(_ req: Request, refreshToken: String) -> EventLoopFuture<UserRefreshToken> {
        let clientRequest = req.eventLoop.tryFuture {
            try self.refreshTokenRequest(refreshToken: refreshToken)
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let refreshTokenContent = clientResponse.flatMap {
            decode(response: $0, request: req, as: UserRefreshToken.self)
        }
        return refreshTokenContent
    }
    
    /// Decodes response's content while taking care of errors.
    ///   - type: Type to decode the content to.
    /// - Throws: OAuthableError in case of error.
    /// - Returns: The decoded content.
    func decode<T>(response res: ClientResponse, request req: Request, as type: T.Type)
    -> EventLoopFuture<T> where T: Content {
        return req.eventLoop.tryFuture {
            if res.status.code < 300, res.status.code >= 200 {
                do {
                    return try res.content.decode(T.self)
                } catch {
                    throw OAuthableError.serverError(
                        status: .badRequest, error: .unknown(error: "\(error)"))
                }
            } else {
                if let error = try? req.query.get(String.self, at: "error"),
                   let authError = OAuthableError.ProviderError(rawValue: error) {
                    throw OAuthableError.providerError(status: res.status, error: authError)
                } else if let error = try? res.content.decode(ErrorResponse.self) {
                    if error.message == "Invalid refresh token" {
                        throw OAuthableError.providerError(status: res.status, error: .invalidToken)
                    } else {
                        throw OAuthableError.providerError(
                            status: res.status, error: .unknown(error: error.message))
                    }
                } else {
                    throw OAuthableError.providerError(
                        status: res.status,
                        error: .unknown(error: res.body?.contentString))
                }
            }
        }
    }
}

//MARK: - Public Declarations

public extension OAuthable {
    /// Tries to acquire an app access token.
    /// - Throws: OAuthableError in case of error.
    func getAppAccessToken(_ req: Request) throws -> EventLoopFuture<AppAccessToken> {
        let clientRequest = try self.getAppAccessTokenRequest()
        let clientResponse = req.client.send(clientRequest)
        let tokenContent = clientResponse.flatMap { res in
            decode(response: res, request: req, as: AppAccessToken.self)
        }
        
        return tokenContent
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    func requestAuthorization(
        _ req: Request,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArgs args: String? = nil)
    throws -> Response {
        let state = String.random(length: 64)
        var authUrl = self.authorizationRedirectUrl(state: state, scopes: scopes)
        if let args = args {
            authUrl = authUrl + "&" + args
        }
        req.session.data["state"] = state
        return req.redirect(to: authUrl)
    }
    
    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    /// - Throws: OAuthableError in case of error.
    func authorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: String, token: UserAccessToken)> {
        
        typealias QueryParams = AuthorizationQueryParameters
        func err<T>(_ error: Error) -> EventLoopFuture<T> {
            req.eventLoop.future(error: error)
        }
        
        guard let params = try? req.query.decode(QueryParams.self) else {
            if let error = try? req.query.get(String.self, at: "error"),
               let oauthError = OAuthableError.ProviderError(rawValue: error) {
                return err(OAuthableError.providerError(status: .badRequest, error: oauthError))
            } else {
                return err(OAuthableError.providerError(
                            status: .badRequest, error: .unknown(error: req.body.string)))
            }
        }
        
        guard let state = req.session.data["state"],
              params.state == state else {
            return err(OAuthableError.serverError(status: .badRequest, error: .invalidCookie))
        }
        req.session.destroy()
        
        let clientRequest = req.eventLoop.future().flatMapThrowing {
            try self.getUserAccessTokenRequest(code: params.code)
        }
        let clientResponse = clientRequest.flatMap { req.client.send($0) }
        let accessTokenContent = clientResponse.flatMap {
            decode(response: $0, request: req, as: UserAccessToken.self)
        }
        
        return accessTokenContent.map({ (state: state, token: $0) })
    }
}

//MARK: - Error Response
private struct ErrorResponse: Decodable {
    let message: String
    let status: Int
}
