import Vapor

/// Protocol to enable `OAuth authorization code flow` actions
public protocol ExplicitFlowAuthorizable: OAuthable { }

extension ExplicitFlowAuthorizable {
    
    /// The url to redirect user to,
    /// so they are asked to give this app permissions to access their data.
    ///
    /// - Throws: OAuthableError in case of error.
    private func authorizationRedirectUrl(
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            responseType: .code,
            redirectUri: state.callbackUrl.rawValue,
            scope: joinScopes(scopes),
            state: state.description)
        let redirectUrl = self.providerAuthorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// After successful completion, they are redirected to the `self.callbackUrl` and we'll
    /// acquire an access-token using the `code` parameter that will be passed to us.
    public func requestAuthorization(
        _ req: Request,
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.trace("OAuth2 authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authUrl = self.authorizationRedirectUrl(state: state, scopes: scopes)
        if let arg = arg {
            authUrl = authUrl + "&" + arg
        }
        state.injectTo(session: req.session)
        return req.redirect(to: authUrl)
    }
    
    /// Takes care of callback endpoint's actions.
    ///
    /// This func is used after the user gets
    /// redirected back to this app by the provider.
    ///
    /// - Throws: OAuthableError in case of error.
    public func authorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: State, token: UserAccessToken)> {
        req.logger.trace("OAuth2 authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        
        guard let stateString = req.query[String.self, at: "state"] else {
            return req.eventLoop.future(error: decodeError(req: req, res: nil))
        }
        let state: State
        do {
            state = try State.extractFrom(session: req.session)
            let urlState = try State(decodeFrom: stateString)
            req.session.destroy()
            guard state == urlState
            else { throw OAuthableError.serverError(error: .invalidCookie) }
        } catch {
            return req.eventLoop.future(error: OAuthableError.providerError(
                error: .unknown(error: error.localizedDescription)))
        }
        
        guard let code = req.query[String.self, at: "code"] else {
            return req.eventLoop.future(error: decodeError(req: req, res: nil))
        }
        
        let clientRequest = req.eventLoop.future().flatMapThrowing {
            try self.userAccessTokenRequest(callbackUrl: state.callbackUrl, code: code)
        }
        let clientResponse = clientRequest.flatMap { req.client.send($0) }
        let accessTokenContent = clientResponse.flatMap {
            decode(response: $0, request: req, as: UserAccessToken.self)
        }
        let stateAndToken = accessTokenContent.map {
            (state: state, token: $0)
        }
        
        return stateAndToken
    }
    
    /// The request that gets an access token from the provider,
    /// using the `code` that this app should acquired after
    /// user being redirected to this app by the provider.
    ///
    /// - Throws: OAuthableError in case of error.
    private func userAccessTokenRequest(callbackUrl: CallbackUrls, code: String)
    throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            redirectUri: callbackUrl.rawValue,
            grantType: .authorizationCode,
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
    /// - Throws: OAuthableError in case of error.
    private func refreshTokenRequest(refreshToken: String) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            grantType: .refreshToken,
            refreshToken: refreshToken)
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
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    public func renewToken(_ req: Request, refreshToken: String)
    -> EventLoopFuture<UserRefreshToken> {
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

