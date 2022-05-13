
/// Protocol to enable `OAuth implicit code flow` actions
///
/// `OAuth implicit code flow` is called `OAuth implicit grant flow` in some places.
public protocol ImplicitFlowAuthorizable: OAuthable { }

extension ImplicitFlowAuthorizable {
    
    /// The URL to redirect user to, so they are asked to give
    /// this app permissions to access their data.
    ///
    /// - Parameters:
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - scopes: The ``OAuthable/Scopes`` to request authorization for.
    /// - Returns: A URL string to redirect users to.
    private func implicitAuthorizationRedirectUrl(
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            responseType: .token,
            redirectUri: state.callbackUrl.rawValue,
            scope: joinScopes(scopes),
            state: state.value)
        let redirectUrl = self.authorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// Upon successful completion, they are redirected to the `self.callbackUrl` and
    /// we will acquire a token with the help of the `implicitAuthorizationCallback(_:)` func.
    ///
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - scopes: The ``OAuthable/Scopes`` to request authorization for.
    ///   - arg: Optional extra argument to be passed to your provider for more customization.
    /// - Returns: A `Response`.
    public func requestImplicitAuthorization(
        _ req: Request,
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.debug("OAuth2 implicit authorization requested.", metadata: [
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
    /// This func is used after the user gets redirected back to this app by the provider.
    ///
    /// - Parameter req: The `Request`.
    /// - Returns: The ``OAuthable/State`` of the request.
    public func implicitAuthorizationCallback(
        _ req: Request
    ) async throws -> State {
        req.logger.debug("OAuth2 implicit authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        
        if let error = decodeErrorIfAvailable(req: req, res: nil) {
            throw error
        }
        let state = try State.extract(from: req.session)

        return state
    }
}
