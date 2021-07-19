import OAuthBM
import Fluent

final class OAuthToken: Content, Model, OAuthTokenRepresentative {
    
        .
        .
        .
    
    static func initializeAndSave(
        request: Request,
        token: RetrievedToken,
        oldToken: OAuthToken?
    ) throws -> EventLoopFuture<OAuthToken> {
        let token = OAuthToken.init(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresIn: token.expiresIn,
            refreshTokenExpiresIn: token.refreshTokenExpiresIn,
            scope: token.scopes,
            tokenType: token.tokenType,
            issuer: token.issuer
        )
        return token
            .save(on: request.db)
            .transform(to: token)
    }
    
        .
        .
        .
}
