
// OAuthable + OAuthTokenConvertible
import Vapor

//MARK: - Public Funcs

public extension OAuthable where Self: OAuthTokenConvertible {

    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    /// - Throws: OAuthableError in case of error.
    func authorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: String, token: Tokens)> {
        var oauthable: some OAuthable { self }
        return oauthable.authorizationCallback(req).flatMap { state, accessToken in
            let oauthToken = accessToken.convertToOAuthToken(
                req: req, issuer: self.issuer, as: Tokens.self)
            return oauthToken.flatMap { token in
                token.save(on: req.db).transform(to: (state, token))
            }
        }
    }
    
    /// Immediately tries to refresh the token.
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    func renewToken(_ req: Request, token: Tokens) -> EventLoopFuture<Tokens> {
        var oauthable: some OAuthable { self }
        let refreshTokenContent = oauthable
            .renewToken(req, refreshToken: token.refreshToken)
        let removeTokenIfRevoked = refreshTokenContent.flatMapAlways {
            result -> EventLoopFuture<UserRefreshToken> in
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
            refreshToken.makeNewOAuthToken(req: req, oldToken: token)
        }
        let saveNewTokenOnDb = newToken.flatMap { newToken -> EventLoopFuture<Tokens>  in
            newToken.save(on: req.db).map { _ in newToken }
        }
        let deleteOldToken = saveNewTokenOnDb.flatMap { newToken in
            token.delete(on: req.db).map { _ in newToken }
        }
        
        return deleteOldToken.map { $0 }
    }
    
    /// Checks if the current token is expired,
    /// tries to acquire a fresh token in case of expiration,
    /// returns the same token if it has not expired.
    func renewTokenIfExpired(_ req: Request, token: Tokens) -> EventLoopFuture<Tokens> {
        if token.hasExpired {
            return renewToken(req, token: token)
        } else {
            return req.eventLoop.future(token)
        }
    }
}
