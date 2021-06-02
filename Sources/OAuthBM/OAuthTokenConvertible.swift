import Vapor
import Fluent

public protocol OAuthTokenConvertible {
    associatedtype Tokens: OAuthTokenRepresentable, Model, Content
}
