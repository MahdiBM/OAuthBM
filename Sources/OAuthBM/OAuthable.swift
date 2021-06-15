import Vapor
import Fluent

/// Enables OAuth-2 tasks.
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
    var providerAuthorizationUrl: String { get }
    
    /// After getting a `code` from the provider when a user has given permissions to this app,
    /// The `code` is passed to this url and in return, an `access token` is acquired.
    var providerTokenUrl: String { get }
    
    /// The policy to encode query parameters with.
    var queryParametersPolicy: Policy { get }
    
    /// The provider which issues these tokens.
    var issuer: Issuer { get }
}

//MARK: - Decoder
extension OAuthable {
    /// Decodes response's content while taking care of errors.
    /// - Throws: OAuthableError in case of error.
    internal func decode<T>(
        response res: ClientResponse,
        request req: Request,
        as type: T.Type
    ) -> EventLoopFuture<T> where T: Content {
        req.eventLoop.tryFuture {
            if res.status.code < 300, res.status.code >= 200 {
                do {
                    return try res.content.decode(T.self)
                } catch {
                    throw OAuthableError.serverError(
                        status: .badRequest, error: .unknown(error: "\(error)"))
                }
            } else {
                if let error = try? req.query.get(String.self, at: "error"),
                   let authError = OAuthableError.ProviderError(rawValue: error) {
                    throw OAuthableError.providerError(status: res.status, error: authError)
                } else if let error = try? res.content.decode(ErrorResponse.self) {
                    if error.message == "Invalid refresh token" {
                        throw OAuthableError.providerError(status: res.status, error: .invalidToken)
                    } else {
                        throw OAuthableError.providerError(
                            status: res.status, error: .unknown(error: error.message))
                    }
                } else {
                    throw OAuthableError.providerError(
                        status: res.status,
                        error: .unknown(error: res.body?.contentString))
                }
            }
        }
    }
}

private struct ErrorResponse: Decodable {
    let message: String
    let status: Int
}
