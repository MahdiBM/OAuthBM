
/// Spotify protocol capable of performing OAuth-2 tasks.
///
/// See ``OAuthable``'s explanations for info about the declarations.
public protocol SpotifyOAuthProvider:
    OAuthTokenConvertible,
    ExplicitFlowAuthorizable,
    ImplicitFlowAuthorizable,
    ClientFlowAuthorizable,
    OAuthTokenRefreshable
where Scopes == SpotifyOAuthScopes {
    
    var clientId: String { get }
    var clientSecret: String { get }
}

//MARK: - Default values

public extension SpotifyOAuthProvider {
    
    //MARK: ``OAuthable`` conformance
    
    /*
     See ``OAuthable`` protocol's explanation for insight about below stuff.
     */
    
    var authorizationUrl: String {
        "https://accounts.spotify.com/authorize"
    }
    var tokenUrl: String {
        "https://accounts.spotify.com/api/token"
    }
    var queryParametersPolicy: Policy {
        .useUrlEncodedForm
    }
    var issuer: Issuer {
        .spotify
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
        "show_dialog=true"
    }
}

//MARK: - Scopes

/// Scopes that you can request authorization for.
///
/// See [Spotify Scopes](https://developer.spotify.com/documentation/general/guides/scopes/) for more info.
public enum SpotifyOAuthScopes: String, CaseIterable {
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

//MARK: - Issuer

extension Issuer {
    public static let spotify = Self(rawValue: "spotify")
}
