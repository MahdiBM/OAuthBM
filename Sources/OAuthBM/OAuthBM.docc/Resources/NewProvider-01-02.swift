import OAuthBM

struct TwitchOAuthProvider: OAuthable {
    
    var clientId = "MyClientId"
    var clientSecret = "MyClientSecret"
    var authorizationUrl: String
    var tokenUrl: String
    var issuer: Issuer
    
    enum Scopes: String, CaseIterable {
        
    }
    
    enum CallbackUrls: String {
        
    }
}
