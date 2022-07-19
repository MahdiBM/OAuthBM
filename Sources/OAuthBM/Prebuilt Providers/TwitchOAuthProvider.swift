
/// Twitch protocol capable of performing OAuth-2 tasks.
public protocol TwitchOAuthProvider:
    OAuthTokenConvertible,
    ExplicitFlowAuthorizable,
    ImplicitFlowAuthorizable,
    ClientFlowAuthorizable,
    OAuthTokenRefreshable,
    OAuthTokenRevocable
where Scopes == TwitchOAuthScopes {
    
    var clientId: String { get }
    var clientSecret: String { get }
}

//MARK: - Default values

public extension TwitchOAuthProvider {
    
    /*
     See corresponding protocol's explanation for insight about below stuff.
     */
    
    //MARK: ``OAuthable`` conformance
    
    var authorizationUrl: String {
        "https://id.twitch.tv/oauth2/authorize"
    }
    var tokenUrl: String {
        "https://id.twitch.tv/oauth2/token"
    }
    var queryParametersPolicy: Policy {
        .useUrlEncodedForm
    }
    var issuer: Issuer {
        .twitch
    }
    
    //MARK: ``OAuthTokenRevocable`` conformance
    
    var revocationUrl: String {
        "https://id.twitch.tv/oauth2/revoke"
    }
    
    //MARK: extras
    
    /// Forces provider to show the verify page/dialog again.
    ///
    /// Passing this as `extraArg` in funcs like `requestAuthorization(_:state:extraArg:)`
    /// will force the provider to show the verify page/dialog again to user.
    /// Without this, provider sometimes shows the page/dialog and sometimes doesn't.
    /// This is provider specific and is extracted from provider's OAuth documentations.
    /// This is not an OAuthable requirement, rather something i added for more comfort when needed.
    var forceVerifyExtraArg: String {
        "force_verify=true"
    }
}

//MARK: - Scopes

/// Scopes that you can request authorization for.
///
/// See [Twitch Scopes](https://dev.twitch.tv/docs/authentication#scopes) for more info.
public enum TwitchOAuthScopes: String, CaseIterable {
    case analyticsReadExtensions = "analytics:read:extensions"
    case analyticsReadGames = "analytics:read:games"
    case bitsRead = "bits:read"
    case channelEditCommercial = "channel:edit:commercial"
    case channelManageBroadcast = "channel:manage:broadcast"
    case channelManageExtensions = "channel:manage:extensions"
    case channelManageModerators = "channel:manage:moderators"
    case channelManagePolls = "channel:manage:polls"
    case channelManagePredictions = "channel:manage:predictions"
    case channelManageRaids = "channel:manage:raids"
    case channelManageRedemptions = "channel:manage:redemptions"
    case channelManageSchedule = "channel:manage:schedule"
    case channelManageVideos = "channel:manage:videos"
    case channelReadEditors = "channel:read:editors"
    case channelReadGoals = "channel:read:goals"
    case channelReadHypeTrain = "channel:read:hype_train"
    case channelReadPolls = "channel:read:polls"
    case channelReadPredictions = "channel:read:predictions"
    case channelReadRedemptions = "channel:read:redemptions"
    case channelReadStreamKey = "channel:read:stream_key"
    case channelReadSubscriptions = "channel:read:subscriptions"
    case channelReadVips = "channel:read:vips"
    case channelManageVips = "channel:manage:vips"
    case clipsEdit = "clips:edit"
    case moderationRead = "moderation:read"
    case moderatorManageAnnouncements = "moderator:manage:announcements"
    case moderatorManageAutomod = "moderator:manage:automod"
    case moderatorReadAutomodSettings = "moderator:read:automod_settings"
    case moderatorManageAutomodSettings = "moderator:manage:automod_settings"
    case moderatorManageBannedUsers = "moderator:manage:banned_users"
    case moderatorReadBlockedTerms = "moderator:read:blocked_terms"
    case moderatorManageBlockedTerms = "moderator:manage:blocked_terms"
    case moderatorManageChatMessages = "moderator:manage:chat_messages"
    case moderatorReadChatSettings = "moderator:read:chat_settings"
    case moderatorManageChatSettings = "moderator:manage:chat_settings"
    case userEdit = "user:edit"
    case userEditFollows = "user:edit:follows"
    case userManageBlockedUsers = "user:manage:blocked_users"
    case userReadBlockedUsers = "user:read:blocked_users"
    case userReadBroadcast = "user:read:broadcast"
    case userManageChatColor = "user:manage:chat_color"
    case userReadEmail = "user:read:email"
    case userReadFollows = "user:read:follows"
    case userReadSubscriptions = "user:read:subscriptions"
    case userManageWhispers = "user:manage:whispers"
    case channelModerate = "channel:moderate"
    case chatEdit = "chat:edit"
    case chatRead = "chat:read"
    case whispersRead = "whispers:read"
    case whispersEdit = "whispers:edit"
}

//MARK: - Issuer

extension Issuer {
    public static let twitch = Self(rawValue: "twitch")
}
