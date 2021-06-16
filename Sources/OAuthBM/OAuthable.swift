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

//MARK: - Decoders
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
                throw decodeError(req: req, res: res)
            }
        }
    }
    
    internal func decodeErrorIfAvailable(req: Request, res: ClientResponse?) -> OAuthableError? {
        if let queryError = QueryError.extractOAuthError(from: req) {
            return queryError
        } else if let res = res,
                  let contentError = ContentError.extractOAuthError(from: res) {
            return contentError
        }
        return nil
    }
    
    internal func decodeError(req: Request, res: ClientResponse?) -> OAuthableError {
        if let error = decodeErrorIfAvailable(req: req, res: res) {
            return error
        } else if let res = res {
            return OAuthableError.providerError(
                status: res.status,
                error: .unknown(error: res.body?.contentString)
            )
        } else {
            return OAuthableError.serverError(error: .unknown(error: req.body.data?.contentString))
        }
    }
}

private struct ContentError: Decodable {
    struct MessageError: Decodable {
        let message: String
        let status: Int
    }
    
    struct ErrorError: Decodable {
        let error: String
    }
    
    static func extractOAuthError(from res: ClientResponse) -> OAuthableError? {
        func oauthError(_ providerError: OAuthableError.ProviderError) -> OAuthableError {
            .providerError(error: providerError)
        }
        if let value = try? res.content.decode(MessageError.self) {
            if let error =  OAuthableError.ProviderError(rawValue: value.message) {
                return oauthError(error)
            } else if let error = OAuthableError.ProviderError(fromDescription: value.message) {
                return oauthError(error)
            }
        } else if let value = try? res.content.decode(ErrorError.self) {
            if let error = OAuthableError.ProviderError(rawValue: value.error) {
                return oauthError(error)
            } else if let error = OAuthableError.ProviderError(fromDescription: value.error) {
                return oauthError(error)
            }
        }
        return nil
    }
}

private struct QueryError: Decodable {
    private let error: String
    private let errorDescription: String
    
    enum CodingKeys: String, CodingKey {
        case error = "error"
        case errorDescription = "error_description"
    }
    
    static func extractOAuthError(from req: Request) -> OAuthableError? {
        guard let value = try? req.query.decode(Self.self),
              let providerError = OAuthableError.ProviderError(rawValue: value.error)
        else { return nil }
        return OAuthableError.providerError(error: providerError)
    }
}
