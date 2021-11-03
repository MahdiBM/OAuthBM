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
    ) async throws -> OAuthToken {
        let token = OAuthToken.init(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresIn: token.expiresIn,
            refreshTokenExpiresIn: token.refreshTokenExpiresIn,
            scope: token.scopes,
            tokenType: token.tokenType,
            issuer: token.issuer
        )
        try await token.save(on: request.db)
        
        return token
    }
    
        .
        .
        .
}
