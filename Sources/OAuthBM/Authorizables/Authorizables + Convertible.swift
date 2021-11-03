
//Protocol extensions `where Self: OAuthTokenConvertible`

//MARK: - ExplicitFlowAuthorizable + OAuthTokenConvertible

public extension ExplicitFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    /// - Parameter req: The `Request`.
    /// - Returns: The ``OAuthable/State`` of the request and the acquired ``OAuthTokenConvertible/Token``.
    func authorizationCallbackWithOAuthToken(
        _ req: Request
    ) async throws -> (state: State, token: Token) {
        req.logger.trace("OAuth2 authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        let authorizationCallback = try await self.authorizationCallback(req)
        let oauthToken = try await authorizationCallback.token.saveToDb(
            req: req,
            oldToken: Optional<Token>.none
        )
        
        return (state: authorizationCallback.state, token: oauthToken)
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
    func getAppAccessOAuthToken(
        _ req: Request,
        scopes: [Scopes] = []
    ) async throws -> Token {
        let appAccessToken = try await self.getAppAccessToken(req, scopes: scopes)
        let oauthToken = try await appAccessToken.saveToDb(
            req: req,
            oldToken: Optional<Token>.none
        )
        
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
    func webAppAuthorizationCallbackWithOAuthToken(
        _ req: Request
    ) async throws -> (state: State, token: Token) {
        req.logger.trace("OAuth2 web app authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        let authorizationCallback = try await self.webAppAuthorizationCallback(req)
        let oauthToken = try await authorizationCallback.token.saveToDb(
            req: req,
            oldToken: Optional<Token>.none
        )
        
        return (state: authorizationCallback.state, token: oauthToken)
    }
}
