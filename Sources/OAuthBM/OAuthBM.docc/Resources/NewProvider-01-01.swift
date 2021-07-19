import OAuthBM

struct TwitchOAuthProvider: OAuthable {
    
    var clientId: String
    var clientSecret: String
    var authorizationUrl: String
    var tokenUrl: String
    var issuer: Issuer
    
    enum Scopes: String, CaseIterable {
        
    }
    
    enum CallbackUrls: String {
        
    }
}
