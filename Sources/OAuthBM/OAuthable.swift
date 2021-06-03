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
    ///
    /// This is part of the `OAuth authorization code flow`
    ///
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
    
    /// The request that gets an access token from the provider.
    ///
    /// This is part of the `OAuth implicit code flow`
    ///
    /// - Throws: OAuthableError in case of error.
    func implicitAuthorizationRedirectUrl(
        state: String = .random(length: 64),
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            response_type: "token",
            redirect_uri: self.callbackUrl,
            scope: scopes.map(\.rawValue).joined(separator: " "),
            state: state)
        let redirectUrl = self.providerAuthorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// The request that gets an access token from the provider,
    /// using the `code` that this app should acquired after
    /// user being redirected to this app by the provider.
    ///
    /// This is part of the `OAuth authorization code flow`
    ///
    /// - Throws: OAuthableError in case of error.
    func userAccessTokenRequest(code: String) throws -> ClientRequest {
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
    ///
    /// This is part of the `OAuth authorization code flow`
    ///
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
    ///
    /// This is part of the `OAuth client credentials flow`
    ///
    /// - Throws: OAuthableError in case of error.
    func appAccessTokenRequest() throws -> ClientRequest {
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
    ///
    /// This is part of the `OAuth authorization code flow`
    ///
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
}

//MARK: - Public Declarations

public extension OAuthable {
    /// Tries to acquire an app access token.
    ///
    /// This is part of the `OAuth client credentials flow`
    ///
    /// - Throws: OAuthableError in case of error.
    func getAppAccessToken(_ req: Request) -> EventLoopFuture<AppAccessToken> {
        let clientRequest = req.eventLoop.tryFuture {
            try self.appAccessTokenRequest()
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let tokenContent = clientResponse.flatMap { res in
            decode(response: res, request: req, as: AppAccessToken.self)
        }
        
        return tokenContent
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// After successful completion, they are redirected to the `self.callbackUrl` and we'll
    /// acquire an access-token using the `code` parameter that will be passed to us.
    ///
    /// This is part of the `OAuth authorization code flow`
    func requestAuthorization(
        _ req: Request,
        state: String? = nil,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.trace("OAuth2 authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        let state = state ?? String.random(length: 64)
        var authUrl = self.authorizationRedirectUrl(state: state, scopes: scopes)
        if let arg = arg {
            authUrl = authUrl + "&" + arg
        }
        req.session.data["state"] = state
        return req.redirect(to: authUrl)
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// This is part of the `OAuth implicit code flow`
    func requestImplicitAuthorization(
        _ req: Request,
        state: String? = nil,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.trace("OAuth2 implicit authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        let state = state ?? String.random(length: 64)
        var authUrl = self.implicitAuthorizationRedirectUrl(scopes: scopes)
        if let arg = arg {
            authUrl = authUrl + "&" + arg
        }
        req.session.data["state"] = state
        return req.redirect(to: authUrl)
    }
    
    /// Takes care of callback endpoint's actions.
    ///
    /// This func is used after the user gets
    /// redirected back to this app by the provider.
    ///
    /// This is part of the `OAuth authorization code flow`
    ///
    /// - Throws: OAuthableError in case of error.
    func authorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: String, token: UserAccessToken)> {
        req.logger.trace("OAuth2 authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        typealias QueryParams = AuthorizationQueryParameters
        func error<T>(_ error: OAuthableError) -> EventLoopFuture<T> {
            req.eventLoop.future(error: error)
        }
        
        guard let params = try? req.query.decode(QueryParams.self) else {
            if let err = try? req.query.get(String.self, at: "error"),
               let oauthError = OAuthableError.ProviderError(rawValue: err) {
                return error(.providerError(error: oauthError))
            } else {
                return error(.providerError(error: .unknown(error: req.body.string)))
            }
        }
        
        guard let state = req.session.data["state"],
              params.state == state else {
            return error(.serverError(error: .invalidCookie))
        }
        req.session.destroy()
        
        let clientRequest = req.eventLoop.future().flatMapThrowing {
            try self.userAccessTokenRequest(code: params.code)
        }
        let clientResponse = clientRequest.flatMap { req.client.send($0) }
        let accessTokenContent = clientResponse.flatMap {
            decode(response: $0, request: req, as: UserAccessToken.self)
        }
        
        return accessTokenContent.map({ (state: state, token: $0) })
    }
}

//MARK: - Decoder func

/// Decodes response's content while taking care of errors.
/// - Throws: OAuthableError in case of error.
private func decode<T>(response res: ClientResponse, request req: Request, as type: T.Type)
-> EventLoopFuture<T> where T: Content {
    req.eventLoop.tryFuture {
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

private struct ErrorResponse: Decodable {
    let message: String
    let status: Int
}
