
/// Protocol to enable `OAuth web application flow` actions
public protocol WebAppFlowAuthorizable: OAuthable { }

extension WebAppFlowAuthorizable {
    
    //MARK: - Authorization
    
    /// The url to redirect user to,
    /// so they are asked to give this app permissions to access their data.
    ///
    /// - Throws: OAuthableError in case of error.
    private func webAppAuthorizationRedirectUrl(state: State) -> String {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            redirectUri: state.callbackUrl.rawValue,
            state: state.value)
        let redirectUrl = self.authorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// After successful completion, they are redirected to the `self.callbackUrl` and we'll
    /// acquire an access-token using the `code` parameter that will be passed to us.
    public func requestWebAppAuthorization(
        _ req: Request,
        state: State,
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.trace("OAuth2 web app authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authUrl = self.webAppAuthorizationRedirectUrl(state: state)
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
    public func webAppAuthorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: State, token: RetrievedToken)> {
        req.logger.trace("OAuth2 web app authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        
        let state: State
        do {
            state = try extractAndValidateState(req: req)
        } catch {
            return req.eventLoop.future(error: error)
        }
        
        guard let code = req.query[String.self, at: "code"] else {
            return req.eventLoop.future(error: decodeError(req: req, res: nil))
        }
        
        let clientRequest = req.eventLoop.future().flatMapThrowing {
            try self.webAppAccessTokenRequest(state: state, code: code)
        }
        let clientResponse = clientRequest.flatMap { req.client.send($0) }
        let accessTokenContent = clientResponse.flatMap {
            decode(response: $0, request: req, as: DecodedToken.self)
        }
        let retrievedToken = accessTokenContent.map {
            $0.convertToRetrievedToken(issuer: self.issuer, flow: .webAppFlow)
        }
        let stateAndToken = retrievedToken.map {
            (state: state, token: $0)
        }
        
        return stateAndToken
    }
    
    //MARK: - Code to Token Request
    
    /// The request that gets an access token from the provider,
    /// using the `code` that this app should acquired after
    /// user being redirected to this app by the provider.
    ///
    /// - Throws: OAuthableError in case of error.
    private func webAppAccessTokenRequest(state: State, code: String)
    throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            redirectUri: state.callbackUrl.rawValue,
            state: state.value,
            code: code)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.tokenUrl)
        
        do {
            try self.queryParametersPolicy.inject(parameters: queryParams, into: &clientRequest)
        } catch {
            throw OAuthableError.serverError(
                status: .preconditionFailed,
                error: .queryParametersEncode(policy: queryParametersPolicy)
            )
        }
        
        return clientRequest
    }
    
    //MARK: - Refreshing Tokens
    
    /// The request to refresh an expired token with.
    ///
    /// - Throws: OAuthableError in case of error.
    private func webAppRefreshTokenRequest(refreshToken: String) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            grantType: .refreshToken,
            refreshToken: refreshToken)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.tokenUrl)
        
        do {
            try self.queryParametersPolicy.inject(parameters: queryParams, into: &clientRequest)
        } catch {
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
    public func refreshWebAppToken(_ req: Request, refreshToken: String)
    -> EventLoopFuture<RetrievedToken> {
        let clientRequest = req.eventLoop.tryFuture {
            try self.webAppRefreshTokenRequest(refreshToken: refreshToken)
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let refreshTokenContent = clientResponse.flatMap {
            decode(response: $0, request: req, as: DecodedToken.self)
        }
        let retrievedToken = refreshTokenContent.map {
            $0.convertToRetrievedToken(issuer: self.issuer, flow: .webAppFlow)
        }
        return retrievedToken
    }
}
