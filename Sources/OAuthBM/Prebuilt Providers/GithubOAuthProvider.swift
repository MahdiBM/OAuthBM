
/// Github protocol capable of performing OAuth-2 tasks.
public protocol GithubOAuthProvider:
    OAuthTokenConvertible,
    WebAppFlowAuthorizable,
    OAuthTokenRefreshable
where Scopes == GithubOAuthScopes {
    
    var clientId: String { get }
    var clientSecret: String { get }
}

//MARK: - Default values

public extension GithubOAuthProvider {
    
    /*
     See corresponding protocol's explanation for insight about below stuff.
     */
    
    //MARK: ``OAuthable`` conformance
    
    var authorizationUrl: String {
        "https://github.com/login/oauth/authorize"
    }
    var tokenUrl: String {
        "https://github.com/login/oauth/access_token"
    }
    var queryParametersPolicy: Policy {
        .useUrlEncodedForm
    }
    var issuer: Issuer {
        .github
    }
    
    //MARK: extras
    
    /// Forces Github to _not_ allow unauthenticated users to signup.
    ///
    /// Github Explanation @ [Github Website](https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps):
    /// "Whether or not unauthenticated users will be offered an option to sign up for GitHub during the OAuth flow. The default is true. Use false when a policy prohibits signups."
    ///
    /// Passing this as `extraArg` in funcs like `requestAuthorization(_:state:extraArg:)`
    /// will enable its functionality.
    /// This is provider specific and is extracted from provider's OAuth documentations.
    /// This is not an OAuthable requirement, rather something i added for more comfort when needed.
    var allowSignupExtraArg: String {
        "allow_signup=false"
    }
}

//MARK: - Scopes

/// Scopes that you can request authorization for.
///
/// See [Github Scopes](https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps) for more info.
public enum GithubOAuthScopes: String, CaseIterable {
    case repo = "repo"
    case repoStatus = "repo:status"
    case repoDeployment = "repo_deployment"
    case publicRepo = "public_repo"
    case repoInvite = "repo:invite"
    case securityEvents = "security_events"
    case adminRepoHook = "admin:repo_hook"
    case writeRepoHook = "write:repo_hook"
    case readRepoHook = "read:repo_hook"
    case adminOrg = "admin:org"
    case writeOrg = "write:org"
    case readOrg = "read:org"
    case adminPublicKey = "admin:public_key"
    case writePublicKey = "write:public_key"
    case readPublicKey = "read:public_key"
    case adminOrgHook = "admin:org_hook"
    case gist = "gist"
    case notifications = "notifications"
    case user = "user"
    case readUser = "read:user"
    case userEmail = "user:email"
    case userFollow = "user:follow"
    case deleteRepo = "delete_repo"
    case writeDiscussion = "write:discussion"
    case readDiscussion = "read:discussion"
    case writePackages = "write:packages"
    case readPackages = "read:packages"
    case deletePackages = "delete:packages"
    case adminGPGKey = "admin:gpg_key"
    case writeGPGKey = "write:gpg_key"
    case readGPGKey = "read:gpg_key"
    case workflow = "workflow"
}

//MARK: - Issuer

extension Issuer {
    public static let github = Self(rawValue: "github")
}
