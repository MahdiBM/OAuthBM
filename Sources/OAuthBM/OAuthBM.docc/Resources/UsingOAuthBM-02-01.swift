import OAuthBM
import Fluent

final class OAuthToken: Content, Model, OAuthTokenRepresentative {
    
    static let schema: String = "oauthToken"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "accessToken")
    var accessToken: String
    
    @Field(key: "refreshToken")
    var refreshToken: String
    
    @Field(key: "expiresIn")
    var expiresIn: Int
    
    @Field(key: "refreshTokenExpiresIn")
    var refreshTokenExpiresIn: Int
    
    @Field(key: "scopes")
    var scopes: [String]
    
    @Field(key: "tokenType")
    var tokenType: String
    
    @Field(key: "issuer")
    var issuer: Issuer
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    static func initializeAndSave(
        request: Request,
        token: RetrievedToken,
        oldToken: OAuthToken?
    ) async throws -> OAuthToken {
        
    }
    
    init() {}
    
    init(
        id: UUID? = nil,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        refreshTokenExpiresIn: Int,
        scope: [String],
        tokenType: String,
        issuer: Issuer
    ) {
        self.id = id
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.refreshTokenExpiresIn = refreshTokenExpiresIn
        self.scopes = scope
        self.tokenType = tokenType
        self.issuer = issuer
    }
}
