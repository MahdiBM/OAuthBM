import Vapor
import Fluent
@testable import OAuthBM

extension OAuthable {
    var fakeAccessTokenClientResponse: ClientResponse {
        let fakeToken = UserAccessToken.init(
            accessToken: .random(length: 60),
            tokenType: "bearer",
            scope: nil,
            scopes: Self.Scopes.allCases.map(\.rawValue),
            expiresIn: .random(in: 2500...36000),
            refreshToken: .random(length: 100)
        )

        var clientResponse = ClientResponse(status: .ok)
        try! clientResponse.content.encode(fakeToken)

        return clientResponse
    }

    var fakeCallbackQueryParameters: AuthorizationQueryParameters {
        .init(code: .random(length: 140), state: .random(length: 64))
    }
}

extension FieldProperty {
    /// Initializes an instance of FieldProperty.
    /// - Parameter key: A value conforming to RawRepresentable where RawValue is String.
    convenience init<Value>(key: Value)
    where Value: RawRepresentable, Value.RawValue == String {
        self.init(key: .init(stringLiteral: key.rawValue))
    }
}

extension FieldKey {
    /// Initializes an instance of FieldKey.
    /// - Parameter key: A value conforming to RawRepresentable where RawValue is String.
    init<Value>(_ key: Value)
    where Value: RawRepresentable, Value.RawValue == String {
        self.init(stringLiteral: key.rawValue)
    }
}
