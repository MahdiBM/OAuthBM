
/// Enables a type to be used to make a Fluent-compatible OAuth-2 token with.
public protocol OAuthTokenConvertible: OAuthable {
    
    /// A Fluent-compatible type representing an OAuth-2 token.
    associatedtype Token: OAuthTokenRepresentative, Model, Content
}
