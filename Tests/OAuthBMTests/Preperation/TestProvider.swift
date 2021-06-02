@testable import OAuthBM

struct TestProvider: OAuthable {
    
    let clientId = "clientId"
    
    let clientSecret = "clientSecret"
    
    var callbackUrl = "http://localhost:9000/v1/oauth/callback"
    
    let providerAuthorizationUrl = "https://id.twitch.tv/oauth2/authorize"
    
    let providerTokenUrl = "https://id.twitch.tv/oauth2/token"
    
    var issuer: Issuer = .twitch
    
    enum Scopes: String, CaseIterable {
        case analyticsReadExtensions = "analytics:read:extensions"
        case analyticsReadGames = "analytics:read:games"
        case bitsRead = "bits:read"
        case channelEditCommercial = "channel:edit:commercial"
        case channelManageBroadcast = "channel:manage:broadcast"
        case channelManageExtensions = "channel:manage:extensions"
        case channelManageRedemptions = "channel:manage:redemptions"
        case channelManageVideos = "channel:manage:videos"
        case channelReadEditors = "channel:read:editors"
        case channelReadHypeTrain = "channel:read:hype_train"
        case channelReadRedemptions = "channel:read:redemptions"
        case channelReadStreamKey = "channel:read:stream_key"
        case channelReadSubscriptions = "channel:read:subscriptions"
        case clipsEdit = "clips:edit"
        case moderationRead = "moderation:read"
        case userEdit = "user:edit"
        case userEditFollows = "user:edit:follows"
        case userReadBlockedUsers = "user:read:blocked_users"
        case userManageBlockedUsers = "user:manage:blocked_users"
        case userReadBroadcast = "user:read:broadcast"
        case userReadEmail = "user:read:email"
        case channelModerate = "channel:moderate"
        case chatEdit = "chat:edit"
        case chatRead = "chat:read"
        case whispersRead = "whispers:read"
        case whispersEdit = "whispers:edit"
    }
}

extension Issuer {
    static let twitch = Self.init(rawValue: "twitch")
}
