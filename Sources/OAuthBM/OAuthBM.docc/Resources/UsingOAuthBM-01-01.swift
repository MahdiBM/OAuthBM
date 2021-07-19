import OAuthBM

struct TwitchOAuthProvider: OAuthable {
    
    var clientId = "MyClientId"
    var clientSecret = "MyClientSecret"
    var authorizationUrl = "https://id.twitch.tv/oauth2/authorize"
    var tokenUrl = "https://id.twitch.tv/oauth2/token"
    var issuer: Issuer = .twitch
    
    enum Scopes: String, CaseIterable {
        case analyticsReadExtensions = "analytics:read:extensions"
        case analyticsReadGames = "analytics:read:games"
        case bitsRead = "bits:read"
            .
            .
            .
    }
    
    enum CallbackUrls: String {
        case firstUrl = "https://myapi.com/authorization/callback"
        case secondUrl = "https://myapi.com/implicitAuthorizationCallback"
    }
}

//MARK: - Issuer

extension Issuer {
    static let twitch = Issuer(rawValue: "twitch")
}

//MARK: - Conformances

extension TwitchOAuthProvider: ExplicitFlowAuthorizable { }
extension TwitchOAuthProvider: ImplicitFlowAuthorizable { }
extension TwitchOAuthProvider: ClientFlowAuthorizable { }
extension TwitchOAuthProvider: OAuthTokenRefreshable { }
extension TwitchOAuthProvider: OAuthTokenRevocable {
    public var revocationUrl: String {
        "https://id.twitch.tv/oauth2/revoke"
    }
}

