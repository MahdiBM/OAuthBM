import Vapor

/// Protocol to enable `OAuth implicit code flow` actions
///
/// `OAuth implicit code flow` is called `OAuth implicit grant flow` in some places.
public protocol ImplicitFlowAuthorizable: OAuthable { }

extension ImplicitFlowAuthorizable {
    
    /// The request that gets an access token from the provider.
    /// - Throws: OAuthableError in case of error.
    private func implicitAuthorizationRedirectUrl(
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            responseType: .token,
            redirectUri: state.callbackUrl.rawValue,
            scope: joinScopes(scopes),
            state: state.description)
        let redirectUrl = self.authorizationUrl + "?" + queryParams.queryString
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
        
        if let error = decodeErrorIfAvailable(req: req, res: nil) {
            return req.eventLoop.future(error: error)
        }
        
        let state = req.eventLoop.tryFuture { () -> State in
            let state = try State.extractFrom(session: req.session)
            req.session.destroy()
            return state
        }
        
        return state
    }
}
