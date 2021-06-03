import Vapor
import Fluent

/// Protocol to enable a type to be made an OAuth-2 token with.
public protocol OAuthTokenConvertible {
    associatedtype Tokens: OAuthTokenRepresentable, Model, Content
}
