import Vapor
import Fluent
@testable import OAuthBM

final class OAuthTokens: Model, Content, OAuthTokenRepresentable {
    
    static let schema = "oauthToken"
    
    @ID var id: UUID?
    
    @Field(key: FieldKeys.accessToken)
    var accessToken: String
    
    @Field(key: FieldKeys.refreshToken)
    var refreshToken: String
    
    @Field(key: FieldKeys.expiresIn)
    var expiresIn: Int
    
    @Field(key: FieldKeys.scopes)
    var scopes: [String]
    
    @Field(key: FieldKeys.tokenType)
    var tokenType: String
    
    @Field(key: FieldKeys.issuer)
    var issuer: Issuer
    
    @Timestamp(key: .init(FieldKeys.createdAt), on: .create)
    var createdAt: Date?
    
    static func initialize(req: Request, token: RetrievedToken, oldToken _: OAuthTokens?)
    throws -> EventLoopFuture<OAuthTokens> {
        req.eventLoop.tryFuture {
            .init(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                expiresIn: token.expiresIn,
                scopes: token.scopes,
                tokenType: token.tokenType,
                issuer: token.issuer
            )
        }
    }
    
    init() { }
    
    init(
        id: UUID? = nil,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        scopes: [String],
        tokenType: String,
        issuer: Issuer
    ) {
        self.id = id
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.scopes = scopes
        self.tokenType = tokenType
        self.issuer = issuer
    }
}

extension OAuthTokens {
    enum FieldKeys: String {
        case accessToken
        case refreshToken
        case expiresIn
        case scopes
        case tokenType
        case issuer
        case createdAt
    }
}

extension OAuthTokens {
    struct Create: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(OAuthTokens.schema)
                .id()
                .field(.init(FieldKeys.accessToken), .string)
                .field(.init(FieldKeys.refreshToken), .string)
                .field(.init(FieldKeys.expiresIn), .int)
                .field(.init(FieldKeys.scopes), .array(of: .string))
                .field(.init(FieldKeys.tokenType), .string)
                .field(.init(FieldKeys.issuer), .string)
                .field(.init(FieldKeys.createdAt), .datetime, .required)
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(OAuthTokens.schema)
                .delete()
        }
    }
}
