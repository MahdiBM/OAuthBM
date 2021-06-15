import Fluent
import Vapor

/// Represents a type which has all necessary requirements of an OAuth-2 access token.
public protocol OAuthTokenRepresentative {
    //MARK: Normal OAuth-2 access-token declarations
    var accessToken: String { get set }
    var refreshToken: String { get set }
    var expiresIn: Int { get set }
    var refreshTokenExpiresIn: Int { get set }
    var scopes: [String] { get set }
    var tokenType: String { get set }
    var issuer: Issuer { get set }
    var createdAt: Date? { get }
    
    /// Initializer for a token. You should also save the token into the db.
    ///
    /// A `Request`, a `RetrievedToken` and the oldToken (if available) are passed
    /// to this func and in return, a new token is expected to be returned.
    /// Using this instead of a normal `init` is only because this is much more
    /// dynamic and much less restrictive.
    static func initializeAndSave(request: Request, token: RetrievedToken, oldToken: Self?)
    throws -> EventLoopFuture<Self>
}

extension OAuthTokenRepresentative {
    /// The expiration date of this token.
    var expiryDate: Date? {
        guard let createdAt = createdAt else {
            return nil
        }
        let errorMargin = 5
        let tokenLifetime = expiresIn  - errorMargin
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(tokenLifetime))
        return expiryDate
    }
    
    /// Whether or not this token has expired.
    var hasExpired: Bool {
        guard let expiryDate = expiryDate else {
            return false
        }
        let now = Date()
        let hasExpired = expiryDate <= now
        return hasExpired == true
    }
}
