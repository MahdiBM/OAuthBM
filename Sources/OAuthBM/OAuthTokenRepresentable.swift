import Fluent
import Vapor

/// Represents a type which has all necessary field of a OAuth-2 access token.
public protocol OAuthTokenRepresentable {
    //MARK: - Normal OAuth-2 access-token declarations
    var accessToken: String { get set }
    var refreshToken: String { get set }
    var expiresIn: Int { get set }
    var scopes: [String] { get set }
    var tokenType: String { get set }
    var issuer: Issuer { get set }
    var createdAt: Date? { get }
    
    /// Dynamic initializer for the token.
    ///
    /// A Request, a RetrievedToken and the oldToken (if available) are passed
    /// to the func and in return, a new token is expected to be returned.
    static func initialize(req: Request, token: RetrievedToken, oldToken: Self?)
    throws -> EventLoopFuture<Self>
}

extension OAuthTokenRepresentable {
    /// The expiration date of this token.
    var expiryDate: Date? {
        guard let createdAt = createdAt else {
            return nil
        }
        let errorMargin = 5
        let tokenLifeLength = expiresIn  - errorMargin
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(tokenLifeLength))
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
