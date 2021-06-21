
/// Twitch model capable of performing OAuth-2 tasks.
///
/// See `OAuthable`'s explanations for info about the declarations.
public struct TwitchOAuthProvider<Token, CallbackUrls>: OAuthable, OAuthTokenConvertible
where Token: Model & Content & OAuthTokenRepresentative,
CallbackUrls: RawRepresentable, CallbackUrls.RawValue == String {
    
    public init(
        clientId: String,
        clientSecret: String,
        tokenType: Token.Type,
        callbackUrlsType: CallbackUrls.Type
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    /*
     See `OAuthable` protocol's explanation for insight about below stuff.
     */
    
    public let clientId: String
    public let clientSecret: String
    public let authorizationUrl = "https://id.twitch.tv/oauth2/authorize"
    public let tokenUrl = "https://id.twitch.tv/oauth2/token"
    public let queryParametersPolicy: Policy = .useUrlEncodedForm
    public let issuer: Issuer = .twitch
    
    /// Scopes that you can request authorization for.
    ///
    /// See [Twitch Scopes](https://dev.twitch.tv/docs/authentication#scopes) for more info.
    public enum Scopes: String, CaseIterable {
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

//MARK: - Other declarations

extension TwitchOAuthProvider {
    
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

//MARK: - Issuer

extension Issuer {
    static let twitch = Self(rawValue: "twitch")
}

//MARK: - Enable related OAuth tasks

extension TwitchOAuthProvider: ExplicitFlowAuthorizable { }
extension TwitchOAuthProvider: ImplicitFlowAuthorizable { }
extension TwitchOAuthProvider: ClientFlowAuthorizable { }
extension TwitchOAuthProvider: OAuthTokenRevocable {
    public var revocationUrl: String {
        "https://id.twitch.tv/oauth2/revoke"
    }
}
