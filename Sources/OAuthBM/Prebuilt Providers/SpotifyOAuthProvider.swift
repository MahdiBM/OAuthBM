
/// Spotify model capable of performing OAuth-2 tasks.
///
/// See ``OAuthable``'s explanations for info about the declarations.
public struct SpotifyOAuthProvider<Token, CallbackUrls>: OAuthable, OAuthTokenConvertible
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
    
    public let clientId: String
    public let clientSecret: String
    public let authorizationUrl = "https://accounts.spotify.com/authorize"
    public let tokenUrl = "https://accounts.spotify.com/api/token"
    public let queryParametersPolicy: Policy = .useUrlEncodedForm
    public let issuer: Issuer = .spotify
    
    /// Scopes that you can request authorization for.
    ///
    /// See [Spotify Scopes](https://developer.spotify.com/documentation/general/guides/scopes/) for more info.
    public enum Scopes: String, CaseIterable {
        case ugcImageUpload = "ugc-image-upload"
        case userReadRecentlyPlayed = "user-read-recently-played"
        case userTopRead = "user-top-read"
        case userReadPlaybackPosition = "user-read-playback-position"
        case userReadPlaybackState = "user-read-playback-state"
        case userModifyPlaybackState = "user-modify-playback-state"
        case userReadCurrentlyPlaying = "user-read-currently-playing"
        case appRemoteControl = "app-remote-control"
        case streaming = "streaming"
        case playlistModifyPublic = "playlist-modify-public"
        case playlistModifyPrivate = "playlist-modify-private"
        case playlistReadPrivate = "playlist-read-private"
        case playlistReadCollaborative = "playlist-read-collaborative"
        case userFollowModify = "user-follow-modify"
        case userFollowRead = "user-follow-read"
        case userLibraryModify = "user-library-modify"
        case userLibraryRead = "user-library-read"
        case userReadEmail = "user-read-email"
        case userReadPrivate = "user-read-private"
    }
}

//MARK: - Other declarations

extension SpotifyOAuthProvider {
    
    /// Forces provider to show the verify page/dialog again.
    ///
    /// Passing this as `extraArg` in funcs like `requestAuthorization(_:state:extraArg:)`
    /// will force the provider to show the verify page/dialog again to user.
    /// Without this, provider sometimes shows the page/dialog and sometimes doesn't.
    /// This is provider specific and is extracted from provider's OAuth documentations.
    /// This is not an OAuthable requirement, rather something i added for more comfort when needed.
    var forceVerifyExtraArg: String {
        "show_dialog=true"
    }
}

//MARK: - Issuer

extension Issuer {
    static let spotify = Self(rawValue: "spotify")
}

//MARK: - Enable related OAuth tasks

extension SpotifyOAuthProvider: ExplicitFlowAuthorizable { }
extension SpotifyOAuthProvider: ImplicitFlowAuthorizable { }
extension SpotifyOAuthProvider: ClientFlowAuthorizable { }
extension SpotifyOAuthProvider: OAuthTokenRefreshable { }
