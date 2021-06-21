////import Fluent
//@testable import OAuthBM
//
//// Fro documentation, read ``OAuthTokenRepresentative``'s documentations.
//
//final class OAuthToken: Model, Content, OAuthTokenRepresentative {
//    
//    static let schema = "oauthToken"
//    
//    @ID var id: UUID?
//    
//    @Field(key: FieldKeys.accessToken)
//    var accessToken: String
//    
//    @Field(key: FieldKeys.refreshToken)
//    var refreshToken: String
//    
//    @Field(key: FieldKeys.expiresIn)
//    var expiresIn: Int
//    
//    @Field(key: FieldKeys.scopes)
//    var scopes: [String]
//    
//    @Field(key: FieldKeys.tokenType)
//    var tokenType: String
//    
//    @Field(key: FieldKeys.issuer)
//    var issuer: Issuer
//    
//    @Timestamp(key: .init(FieldKeys.createdAt), on: .create)
//    var createdAt: Date?
//    
//    static func initializeAndSave(request: Request, token: RetrievedToken, oldToken _: OAuthToken?)
//    throws -> EventLoopFuture<OAuthToken> {
//            let token = OAuthToken.init(
//                accessToken: token.accessToken,
//                refreshToken: token.refreshToken,
//                expiresIn: token.expiresIn,
//                scopes: token.scopes,
//                tokenType: token.tokenType,
//                issuer: token.issuer
//            )
//        return token.save(on: request.db).transform(to: token)
//    }
//    
//    init() { }
//    
//    init(
//        id: UUID? = nil,
//        accessToken: String,
//        refreshToken: String,
//        expiresIn: Int,
//        scopes: [String],
//        tokenType: String,
//        issuer: Issuer
//    ) {
//        self.id = id
//        self.accessToken = accessToken
//        self.refreshToken = refreshToken
//        self.expiresIn = expiresIn
//        self.scopes = scopes
//        self.tokenType = tokenType
//        self.issuer = issuer
//    }
//}
//
////MARK: - FieldKeys
//
//extension OAuthToken {
//    enum FieldKeys: String {
//        case accessToken
//        case refreshToken
//        case expiresIn
//        case scopes
//        case tokenType
//        case issuer
//        case createdAt
//    }
//}
//
////MARK: - Migrations
//
//extension OAuthToken {
//    struct Create: Migration {
//        func prepare(on database: Database) -> EventLoopFuture<Void> {
//            database.schema(OAuthToken.schema)
//                .id()
//                .field(.init(FieldKeys.accessToken), .string)
//                .field(.init(FieldKeys.refreshToken), .string)
//                .field(.init(FieldKeys.expiresIn), .int)
//                .field(.init(FieldKeys.scopes), .array(of: .string))
//                .field(.init(FieldKeys.tokenType), .string)
//                .field(.init(FieldKeys.issuer), .string)
//                .field(.init(FieldKeys.createdAt), .datetime, .required)
//                .create()
//        }
//        
//        func revert(on database: Database) -> EventLoopFuture<Void> {
//            database.schema(OAuthToken.schema)
//                .delete()
//        }
//    }
//}
//
////MARK: - Private extensions
//
//private extension FieldProperty {
//    /// Initializes an instance of FieldProperty.
//    /// - Parameter key: A value conforming to RawRepresentable where RawValue is String.
//    convenience init<Value>(key: Value)
//    where Value: RawRepresentable, Value.RawValue == String {
//        self.init(key: .init(stringLiteral: key.rawValue))
//    }
//}
//
//private extension FieldKey {
//    /// Initializes an instance of FieldKey.
//    /// - Parameter key: A value conforming to RawRepresentable where RawValue is String.
//    init<Value>(_ key: Value)
//    where Value: RawRepresentable, Value.RawValue == String {
//        self.init(stringLiteral: key.rawValue)
//    }
//}
