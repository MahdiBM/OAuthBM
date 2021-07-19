import OAuthBM

struct TwitchOAuthProvider: OAuthable {
    
    var clientId = "MyClientId"
    var clientSecret = "MyClientSecret"
    var authorizationUrl = "https://id.twitch.tv/oauth2/authorize"
    var tokenUrl = "https://id.twitch.tv/oauth2/token"
    var issuer: Issuer = .twitch
    
    enum Scopes: String, CaseIterable {
        
    }
    
    enum CallbackUrls: String {
        
    }
}

extension Issuer {
    static let twitch = Issuer(rawValue: "twitch")
}
