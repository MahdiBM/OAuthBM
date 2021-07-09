
/// Reddit model capable of performing OAuth-2 tasks.
///
/// See ``OAuthable``'s explanations for info about the declarations.
public struct RedditOAuthProvider<Token, CallbackUrls>: OAuthable, OAuthTokenConvertible
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
    
    public typealias Scopes = RedditOAuthScopes
    
    public let clientId: String
    public let clientSecret: String
    public let authorizationUrl = "https://www.reddit.com/api/v1/authorize"
    public let tokenUrl = "https://www.reddit.com/api/v1/access_token"
    public let queryParametersPolicy: Policy = .useUrlEncodedForm
    public let issuer: Issuer = .reddit
}

//MARK: - Scopes

/// Scopes that you can request authorization for.
///
/// See [Reddit Scopes](https://www.reddit.com/dev/api/oauth) for more info.
public enum RedditOAuthScopes: String, CaseIterable {
    case account = "account"
    case creddits = "creddits"
    case edit = "edit"
    case flair = "flair"
    case history = "history"
    case identity = "identity"
    case liveManage = "livemanage"
    case modConfig = "modconfig"
    case modContributors = "modcontributors"
    case modFlair = "modflair"
    case modLog = "modlog"
    case modMail = "modmail"
    case modOthers = "modothers"
    case modPosts = "modposts"
    case modSelf = "modself"
    case modWiki = "modwiki"
    case mySubreddits = "mysubreddits"
    case privateMessages = "privatemessages"
    case read = "read"
    case report = "report"
    case save = "save"
    case structuredStyles = "structuredstyles"
    case submit = "submit"
    case subscribe = "subscribe"
    case vote = "vote"
    case wikiEdit = "wikiedit"
    case wikiRead = "wikiread"
}

//MARK: - Other declarations

extension RedditOAuthProvider {
    
    /// Forces Reddit to produce a refreshable token.
    ///
    /// Reddit Explanation @ [Reddit Website](https://github.com/reddit-archive/reddit/wiki/OAuth2):
    /// "Indicates whether or not your app needs a permanent token. All bearer tokens expire after 1 hour. If you indicate you need permanent access to a user's account, you will additionally receive a refresh_token when acquiring the bearer token. You may use the refresh_token to acquire a new bearer token after your current token expires. Choose temporary if you're completing a one-time request for the user (such as analyzing their recent comments); choose permanent if you will be performing ongoing tasks for the user, such as notifying them whenever they receive a private message. The implicit grant flow does not allow permanent tokens."
    ///
    /// Passing this as `extraArg` in funcs like `requestAuthorization(_:state:extraArg:)`
    /// will enable its functionality.
    /// This is provider specific and is extracted from provider's OAuth documentations.
    /// This is not an OAuthable requirement, rather something i added for more comfort when needed.
    var tokenDurationExtraArg: String {
        "duration=permanent"
    }
}

//MARK: - Issuer

extension Issuer {
    static let reddit = Self(rawValue: "reddit")
}

//MARK: - Enable related OAuth tasks

extension RedditOAuthProvider: ExplicitFlowAuthorizable { }
extension RedditOAuthProvider: ClientFlowAuthorizable { }
extension RedditOAuthProvider: OAuthTokenRefreshable { }
extension RedditOAuthProvider: OAuthTokenRevocable {
    public var revocationUrl: String {
        "https://www.reddit.com/api/v1/revoke_token"
    }
}
extension RedditOAuthProvider: OAuthTokenBasicAuthRequirement {
    public var tokenRequestsRequireBasicAuthentication: Bool {
        true
    }
}
