import Vapor

/// Protocol to enable `OAuth implicit code flow` actions
public protocol ImplicitFlowAuthorizable: OAuthable { }

extension ImplicitFlowAuthorizable {
    
    /// The request that gets an access token from the provider.
    /// - Throws: OAuthableError in case of error.
    private func implicitAuthorizationRedirectUrl(
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            response_type: "token",
            redirect_uri: state.callbackUrl.rawValue,
            scope: scopes.map(\.rawValue).joined(separator: " "),
            state: state.description)
        let redirectUrl = self.providerAuthorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    public func requestImplicitAuthorization(
        _ req: Request,
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.trace("OAuth2 implicit authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authUrl = self.implicitAuthorizationRedirectUrl(state: state, scopes: scopes)
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
    public func implicitAuthorizationCallback(_ req: Request) -> EventLoopFuture<State> {
        req.logger.trace("OAuth2 implicit authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        
        func error<T>(_ error: OAuthableError) -> EventLoopFuture<T> {
            req.eventLoop.future(error: error)
        }
        if let err = try? req.query.get(String.self, at: "error") {
            if let oauthError = OAuthableError.ProviderError(rawValue: err) {
                return error(.providerError(error: oauthError))
            } else {
                return error(.providerError(error: .unknown(error: err)))
            }
        }
        
        let state = req.eventLoop.tryFuture { () -> State in
            let state = try State.extractFrom(session: req.session)
            req.session.destroy()
            return state
        }
        
        return state
    }
}