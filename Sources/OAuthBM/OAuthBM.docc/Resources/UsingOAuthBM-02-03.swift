import Fluent

extension OAuthToken {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database
                .schema(OAuthToken.schema)
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
        
        func revert(on database: Database) async throws {
            try await database
                .schema(OAuthToken.schema)
                .delete()
        }
    }
}
