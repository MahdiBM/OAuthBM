
//MARK: - OAuthTokenRevocable + OAuthTokenConvertible

public extension OAuthTokenRevocable where Self: OAuthTokenConvertible {
    
    /// Immediately tries to revoke the token. Deletes the token from db in case of success.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - token: The ``OAuthTokenConvertible/Token``.
    /// - Returns: A `Void` signal indicating success.
    func revokeToken(
        _ req: Request,
        token: Token
    ) -> EventLoopFuture<Void> {
        let revocation = self.revokeToken(req, accessToken: token.accessToken)
        let deletion = revocation.flatMap {
            token.delete(on: req.db)
        }
        
        return deletion
    }
}

//MARK: - OAuthTokenRevocable + OAuthTokenRefreshable

public extension OAuthTokenRefreshable where Self: OAuthTokenConvertible {
    
    /// Immediately tries to refresh the token.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - token: The ``OAuthTokenConvertible/Token`` to be refreshed.
    /// - Returns: A fresh token.
    func refreshToken(
        _ req: Request,
        token: Token
    ) -> EventLoopFuture<Token> {
        var refreshTokenContent: EventLoopFuture<RetrievedToken> {
            self.refreshToken(req, refreshToken: token.refreshToken)
        }
        let newToken = refreshTokenContent.flatMap { refreshToken in
            refreshToken.saveToDb(req: req, oldToken: token)
        }
        let deleteOldToken = newToken.flatMap { newToken in
            token.delete(on: req.db).map { _ in newToken }
        }
        
        return deleteOldToken.map { $0 }
    }
    
    /// Refreshes the token if needed.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - token: The ``OAuthTokenConvertible/Token`` to be refreshed.
    /// - Returns: The same token if not expired, otherwise a fresh token.
    func refreshTokenIfExpired(
        _ req: Request,
        token: Token
    ) -> EventLoopFuture<Token> {
        if token.tokenHasExpired && token.isRefreshableToken {
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
