import OAuthBM

/// For clarification, this provider won't work in a real app unless
/// You replace `clientId`, `clientSecret` and `CallbackUrls` with real values.
/// `providerAuthorizationUrl`, `providerTokenUrl` and `Scopes` are
/// `Twitch` specific values and if you're using this for any other provider,
/// you must enter the correct values for them yourself.

//let testTwitchProvider = TwitchOAuthProvider.init(
//    clientId: "",
//    clientSecret: "",
//    tokensType: OAuthTokens.self,
//    callbackUrlsType: CallbackUrls.self)
//
//enum CallbackUrls: String {
//    case normal = "http://localhost:8080/oauth/callbacks/normal"
//    case implicit = "http://localhost:8080/oauth/callbacks/implicit"
//}
