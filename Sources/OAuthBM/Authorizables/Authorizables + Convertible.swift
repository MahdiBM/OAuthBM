
//Protocol extensions `where Self: OAuthTokenConvertible`

//MARK: - ExplicitFlowAuthorizable + OAuthTokenConvertible

public extension ExplicitFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    /// - Parameter req: The `Request`.
    /// - Returns: The ``OAuthable/State`` of the request and the acquired ``OAuthTokenConvertible/Token``.
    func authorizationCallback(_ req: Request) -> EventLoopFuture<(state: State, token: Token)> {
        req.logger.trace("OAuth2 authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authorizationCallback: EventLoopFuture<(state: State, token: RetrievedToken)>  {
            self.authorizationCallback(req)
        }
        return authorizationCallback.flatMap { state, accessToken in
            accessToken.saveToDb(req: req, oldToken: nil)
                .map({ (state: state, token: $0) })
        }
    }
}

//MARK: - ClientFlowAuthorizable + OAuthTokenConvertible

public extension ClientFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Tries to acquire an app access token.
    ///
    /// `scopes` defaults to an empty array because most providers
    /// don't require/need scopes specified for app access tokens.
    ///
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - scopes: The ``OAuthable/Scopes`` to get access token for.
    /// - Returns: The acquired ``OAuthTokenConvertible/Token``.
    func getAppAccessToken(_ req: Request, scopes: [Scopes] = [])
    -> EventLoopFuture<Token> {
        var appAccessToken: EventLoopFuture<RetrievedToken> {
            self.getAppAccessToken(req, scopes: scopes)
        }
        let oauthToken = appAccessToken.flatMap {
            token -> EventLoopFuture<Token> in
            token.saveToDb(req: req, oldToken: nil)
        }
        return oauthToken
    }
}

//MARK: - WebAppFlowAuthorizable + OAuthTokenConvertible

public extension WebAppFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    /// - Parameter req: The `Request`.
    /// - Returns: The ``OAuthable/State`` of the request and the acquired ``OAuthTokenConvertible/Token``.
    func webAppAuthorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: State, token: Token)> {
        req.logger.trace("OAuth2 web app authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authorizationCallback: EventLoopFuture<(state: State, token: RetrievedToken)> {
            self.webAppAuthorizationCallback(req)
        }
        return authorizationCallback.flatMap { state, accessToken in
            accessToken.saveToDb(req: req, oldToken: nil)
                .map({ (state: state, token: $0) })
        }
    }
}
