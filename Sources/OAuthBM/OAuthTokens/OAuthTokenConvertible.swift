import Fluent

/// Enables a type to be used to make an OAuth-2 token with.
public protocol OAuthTokenConvertible: OAuthable {
    
    associatedtype Token: OAuthTokenRepresentative, Model, Content
}
