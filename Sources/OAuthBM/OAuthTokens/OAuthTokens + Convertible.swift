
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
    ) async throws {
        try await self.revokeToken(req, accessToken: token.accessToken)
        try await token.delete(on: req.db)
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
    ) async throws -> Token {
        let refreshToken = try await refreshToken(req, refreshToken: token.refreshToken)
        let newToken = try await refreshToken.saveToDb(req: req, oldToken: token)
        try await token.delete(on: req.db)
        
        return newToken
    }
    
    /// Refreshes the token if needed.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - token: The ``OAuthTokenConvertible/Token`` to be refreshed.
    /// - Returns: The same token if not expired, otherwise a fresh token.
    func refreshTokenIfExpired(
        _ req: Request,
        token: Token
    ) async throws -> Token {
        if token.tokenHasExpired && token.isRefreshableToken {
            req.logger.debug("Token has expired. Will try to acquire new one.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return try await refreshToken(req, token: token)
        } else {
            req.logger.debug("Token has not expired. Will return the current token.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return token
        }
    }
}
