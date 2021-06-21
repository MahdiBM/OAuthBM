
//MARK: - OAuthTokenRevocable + OAuthTokenConvertible

public extension OAuthTokenRevocable where Self: OAuthTokenConvertible {
    
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
