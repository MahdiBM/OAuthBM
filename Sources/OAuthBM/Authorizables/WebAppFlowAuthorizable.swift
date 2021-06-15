import Vapor

/// Protocol to enable `OAuth web application flow` actions
public protocol WebAppFlowAuthorizable: OAuthable { }

extension WebAppFlowAuthorizable {
    
    /// The url to redirect user to,
    /// so they are asked to give this app permissions to access their data.
    ///
    /// - Throws: OAuthableError in case of error.
    private func webAppAuthorizationRedirectUrl(state: State) -> String {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            redirect_uri: state.callbackUrl.rawValue,
            state: state.description)
        let redirectUrl = self.providerAuthorizationUrl + "?" + queryParams.queryString
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
        req.logger.trace("OAuth2 authorization requested.", metadata: [
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
    -> EventLoopFuture<(state: State, token: UserAccessToken)> {
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
        
        let state: State
        do {
            state = try State.extractFrom(session: req.session)
            let urlState = try State(decodeFrom: params.state)
            req.session.destroy()
            guard state == urlState
            else { throw OAuthableError.serverError(error: .invalidCookie) }
        } catch {
            return req.eventLoop.future(error: error)
        }
        
        let clientRequest = req.eventLoop.future().flatMapThrowing {
            try self.webAppAccessTokenRequest(
                callbackUrl: state.callbackUrl, state: state, code: params.code)
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
    private func webAppAccessTokenRequest(callbackUrl: CallbackUrls, state: State, code: String)
    throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            client_secret: self.clientSecret,
            redirect_uri: callbackUrl.rawValue,
            state: state.description,
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
}
