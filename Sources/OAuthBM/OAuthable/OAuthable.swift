import Fluent

/// Basic OAuth-2 requirements.
public protocol OAuthable {
    
    /// The State container type.
    typealias State = StateContainer<CallbackUrls>
    
    /// Convenience typealias for the type representing
    /// the policy to encode query parameters with.
    typealias Policy = QueryParametersPolicy
    
    /// Scopes that the app can get permissions to access.
    ///
    /// An enum conforming to `String` and `CaseIterable` is the best way.
    associatedtype Scopes: CaseIterable & RawRepresentable
    where Scopes.RawValue == String
    
    /// Your callback urls.
    /// 
    /// All must be registered the callback urls in your provider's panel.
    associatedtype CallbackUrls: RawRepresentable
    where CallbackUrls.RawValue == String
    
    /// Your client id, acquired after registering your app in your provider's panel.
    var clientId: String { get }
    
    /// Your client secret, acquired after registering your app in your provider's panel.
    var clientSecret: String { get }
    
    /// Provider's endpoint that you redirect users to,
    /// so they are asked to give permissions to this app.
    var authorizationUrl: String { get }
    
    /// After getting a `code` from the provider when a user has given permissions to this app,
    /// The `code` is passed to this url and in return, an `access token` is acquired.
    var tokenUrl: String { get }
    
    /// The policy to encode query parameters with.
    var queryParametersPolicy: Policy { get }
    
    /// The provider which issues these tokens.
    var issuer: Issuer { get }
}
