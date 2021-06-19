import Vapor

//MARK: - ExplicitFlowAuthorizable + OAuthTokenConvertible

public extension ExplicitFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    ///
    /// - Throws: OAuthableError in case of error.
    func authorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: State, token: Token)> {
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
    
    /// Immediately tries to refresh the token.
    ///
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    func refreshToken(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        var refreshTokenContent: EventLoopFuture<RetrievedToken> {
            self.refreshToken(req, refreshToken: token.refreshToken)
        }
        let removeTokenIfRevoked = refreshTokenContent.flatMapAlways {
            result -> EventLoopFuture<RetrievedToken> in
            switch result {
            case let .success(token): return req.eventLoop.future(token)
            case let .failure(error):
                if let error = error as? OAuthableError,
                   error == .providerError(status: .badRequest, error: .invalidToken) {
                    /// Delete the token if its been revoked.
                    return token.delete(on: req.db)
                        .flatMapThrowing({ throw error })
                } else {
                    return req.eventLoop.future(error: error)
                }
            }
        }
        let newToken = removeTokenIfRevoked.flatMap { refreshToken in
            refreshToken.saveToDb(req: req, oldToken: token)
        }
        let deleteOldToken = newToken.flatMap { newToken in
            token.delete(on: req.db).map { _ in newToken }
        }
        
        return deleteOldToken.map { $0 }
    }
    
    /// Refreshes the token if needed.
    ///
    /// - Returns: The same token if not expired, otherwise a fresh token.
    func refreshTokenIfExpired(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        if token.tokenHasExpired && token.tokenIsRefreshable {
            req.logger.trace("Token has expired. Will try to acquire new one.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return refreshToken(req, token: token)
        } else {
            req.logger.trace("Token has not expired. Will return the current token.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return req.eventLoop.future(token)
        }
    }
}

//MARK: - ClientFlowAuthorizable + OAuthTokenConvertible

public extension ClientFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Tries to acquire an app access token.
    ///
    /// - Throws: OAuthableError in case of error.
    func getAppAccessToken(_ req: Request, scopes: [Scopes] = []) -> EventLoopFuture<Token> {
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
    ///
    /// - Throws: OAuthableError in case of error.
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
    
    /// Immediately tries to refresh the token.
    ///
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    func refreshWebAppToken(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        var refreshTokenContent: EventLoopFuture<RetrievedToken> {
            self.refreshWebAppToken(req, refreshToken: token.refreshToken)
        }
        #warning("remove this?!? (and the other one)")
        let removeTokenIfRevoked = refreshTokenContent.flatMapAlways {
            result -> EventLoopFuture<RetrievedToken> in
            switch result {
            case let .success(token): return req.eventLoop.future(token)
            case let .failure(error):
                if let error = error as? OAuthableError,
                   error == .providerError(status: .badRequest, error: .invalidToken) {
                    /// Delete the token if its been revoked.
                    return token.delete(on: req.db)
                        .flatMapThrowing({ throw error })
                } else {
                    return req.eventLoop.future(error: error)
                }
            }
        }
        let newToken = removeTokenIfRevoked.flatMap { refreshToken in
            refreshToken.saveToDb(req: req, oldToken: token)
        }
        let deleteOldToken = newToken.flatMap { newToken in
            token.delete(on: req.db).map { _ in newToken }
        }
        
        return deleteOldToken.map { $0 }
    }
    
    /// Refreshes the token if needed.
    ///
    /// - Returns: The same token if not expired, otherwise a fresh token.
    func refreshWebAppTokenIfExpired(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        if token.tokenHasExpired {
            req.logger.trace("Token has expired. Will try to acquire new one.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return refreshWebAppToken(req, token: token)
        } else {
            req.logger.trace("Token has not expired. Will return the current token.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return req.eventLoop.future(token)
        }
    }
}

//MARK: - OAuthTokenRevocable + OAuthTokenConvertible

extension OAuthTokenRevocable where Self: OAuthTokenConvertible {
    
    /// Immediately tries to revoke the token.
    /// Deletes the token from db in case of success.
    ///
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A Void signal indicating success.
    func revokeToken(_ req: Request, token: Token) -> EventLoopFuture<Void> {
        let revocation = self.revokeToken(req, accessToken: token.accessToken)
        let deletion = revocation.flatMap {
            token.delete(on: req.db)
        }
        
        return deletion
    }
}
