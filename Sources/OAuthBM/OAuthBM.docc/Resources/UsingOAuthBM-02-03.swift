import Fluent

extension OAuthToken {
    struct Create: Fluent.Migration {
        func prepare(on database: Database) -> ELF<Void> {
            database.schema(OAuthToken.schema)
                .id()
                .field("accessToken", .string)
                .field("refreshToken", .string)
                .field("expiresIn", .int)
                .field("refreshTokenExpiresIn", .int)
                .field("scopes", .array(of: .string))
                .field("tokenType", .string)
                .field("issuer", .string)
                .field("createdAt", .datetime, .required)
                .create()
        }
        
        func revert(on database: Database) -> ELF<Void> {
            database.schema(OAuthToken.schema)
                .delete()
        }
    }
}
