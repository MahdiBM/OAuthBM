import OAuthBM

extension TwitchOAuthProvider: ExplicitFlowAuthorizable { }
extension TwitchOAuthProvider: ClientFlowAuthorizable { }
extension TwitchOAuthProvider: ImplicitFlowAuthorizable { }
extension TwitchOAuthProvider: OAuthTokenRefreshable { }
extension TwitchOAuthProvider: OAuthTokenRevocable {
    public var revocationUrl: String {
        "https://id.twitch.tv/oauth2/revoke"
    }
}
