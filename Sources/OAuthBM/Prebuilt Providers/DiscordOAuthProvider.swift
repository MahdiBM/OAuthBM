
/// Discord protocol capable of performing OAuth-2 tasks.
public protocol DiscordOAuthProvider:
    OAuthTokenConvertible,
    ExplicitFlowAuthorizable,
    ImplicitFlowAuthorizable,
    ClientFlowAuthorizable,
    OAuthTokenRefreshable,
    OAuthTokenRevocable
where Scopes == DiscordOAuthScopes {
    
    var clientId: String { get }
    var clientSecret: String { get }
}

//MARK: - Default values

public extension DiscordOAuthProvider {
    
    /*
     See corresponding protocol's explanation for insight about below stuff.
     */
    
    //MARK: ``OAuthable`` conformance
    
    var authorizationUrl: String {
        "https://discord.com/api/oauth2/authorize"
    }
    var tokenUrl: String {
        "https://discord.com/api/oauth2/token"
    }
    var queryParametersPolicy: Policy {
        .useUrlEncodedForm
    }
    var issuer: Issuer {
        .discord
    }
    
    //MARK: ``OAuthTokenRevocable`` conformance
    
    var revocationUrl: String {
        "https://discord.com/api/oauth2/token/revoke"
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
        "prompt=consent"
    }
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
    case applicationsCommandsPermissionsUpdate = "applications.commands.permissions.update"
    case applicationsEntitlements = "applications.entitlements"
    case applicationsStoreUpdate = "applications.store.update"
    case bot = "bot"
    case connections = "connections"
    case email = "email"
    case gdmJoin = "gdm.join"
    case guilds = "guilds"
    case guildsJoin = "guilds.join"
    case guildsMembersRead = "guilds.members.read"
    case identify = "identify"
    case messagesRead = "messages.read"
    case relationshipsRead = "relationships.read"
    case rpc = "rpc"
    case rpcActivitiesWrite = "rpc.activities.write"
    case rpcNotificationsRead = "rpc.notifications.read"
    case rpcVoiceRead = "rpc.voice.read"
    case rpcVoiceWrite = "rpc.voice.write"
    case webhookIncoming = "webhook.incoming"
    
    /// All cases that will work for any authorization request.
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

//MARK: - Issuer

extension Issuer {
    public static let discord = Self(rawValue: "discord")
}
