
/// Discord model capable of performing OAuth-2 tasks.
///
/// See ``OAuthable``'s explanations for info about the declarations.
public struct DiscordOAuthProvider<Token, CallbackUrls>: OAuthable, OAuthTokenConvertible
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
     See ``OAuthable`` protocol's explanation for insight about below stuff.
     */
    
    public typealias Scopes = DiscordOAuthScopes
    
    public let clientId: String
    public let clientSecret: String
    public let authorizationUrl = "https://discord.com/api/oauth2/authorize"
    public let tokenUrl = "https://discord.com/api/oauth2/token"
    public let queryParametersPolicy: Policy = .useUrlEncodedForm
    public let issuer: Issuer = .discord
}

//MARK: - Scopes

/// Scopes that you can request authorization for.
///
/// See [Discord Scopes](https://discord.com/developers/docs/topics/oauth2#shared-resources-oauth2-scopes) for more info.
public enum DiscordOAuthScopes: String, CaseIterable {
    case activitiesRead = "activities.read"
    case activitiesWrite = "activities.write"
    case applicationsBuildsRead = "applications.builds.read"
    case applicationsBuildsUpload = "applications.builds.upload"
    case applicationsCommands = "applications.commands"
    case applicationsCommandsUpdate = "applications.commands.update"
    case applicationsEntitlements = "applications.entitlements"
    case applicationsStoreUpdate = "applications.store.update"
    case bot = "bot"
    case connections = "connections"
    case email = "email"
    case gdmJoin = "gdm.join"
    case guilds = "guilds"
    case guildsJoin = "guilds.join"
    case identify = "identify"
    case messagesRead = "messages.read"
    case relationshipsRead = "relationships.read"
    case rpc = "rpc"
    case rpcActivitiesWrite = "rpc.activities.write"
    case rpcNotificationsRead = "rpc.notifications.read"
    case rpcVoiceRead = "rpc.voice.read"
    case rpcVoiceWrite = "rpc.voice.write"
    case webhookIncoming = "webhook.incoming"
    
    /// All cases which will work for any authorization request.
    public static let allCases: [Self] = [
        /* .activitiesRead, Requires Discord approval */
        /* .activitiesWrite, Requires Discord approval */
        .applicationsBuildsRead,
        /* .applicationsBuildsUpload, Requires Discord approval */
        .applicationsCommands,
        /* .applicationsCommandsUpdate, Client-credentials-flow only */
        .applicationsEntitlements,
        .applicationsStoreUpdate,
        /* .bot, Requires a Bot account connected to your application */
        .connections,
        .email,
        .gdmJoin,
        .guilds,
        /* .guildsJoin, Requires a Bot account connected to your application */
        .identify,
        .messagesRead,
        /* .relationshipsRead, Requires Discord approval */
        /* .rpc, Requires Discord approval */
        /* .rpcActivitiesWrite, Requires Discord approval */
        /* .rpcNotificationsRead, Requires Discord approval */
        /* .rpcVoiceRead, Requires Discord approval */
        /* .rpcVoiceWrite, Requires Discord approval */
        /* .webhookIncoming Authorization-code-flow only */
    ]
}

//MARK: - Other declarations

extension DiscordOAuthProvider {
    
    /// Forces provider to show the verify page/dialog again.
    ///
    /// Passing this as `extraArg` in funcs like `requestAuthorization(_:state:extraArg:)`
    /// will force the provider to show the verify page/dialog again to user.
    /// Without this, provider sometimes shows the page/dialog and sometimes doesn't.
    /// This is provider specific and is extracted from provider's OAuth documentations.
    /// This is not an OAuthable requirement, rather something i added for more comfort when needed.
    var forceVerifyExtraArg: String {
        "prompt=consent"
    }
}

//MARK: - Issuer

extension Issuer {
    public static let discord = Self(rawValue: "discord")
}

//MARK: - Enable related OAuth tasks

extension DiscordOAuthProvider: ExplicitFlowAuthorizable { }
extension DiscordOAuthProvider: ImplicitFlowAuthorizable { }
extension DiscordOAuthProvider: ClientFlowAuthorizable { }
extension DiscordOAuthProvider: OAuthTokenRefreshable { }
extension DiscordOAuthProvider: OAuthTokenRevocable {
    public var revocationUrl: String {
        "https://discord.com/api/oauth2/token/revoke"
    }
}
