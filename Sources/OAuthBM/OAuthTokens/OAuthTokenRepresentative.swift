
/// Represents a type which has all necessary requirements of an OAuth-2 token.
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
    /// A `Request`, a ``RetrievedToken`` and the oldToken (if available) are passed
    /// to this func and in return, a new token is expected to be saved into the
    /// database and  returned.
    /// Using a function instead of a normal `init` is only due to this being much
    /// more dynamic and much less restrictive.
    ///
    /// - Parameters:
    ///   - request: The `Request`.
    ///   - token: The ``RetrievedToken``.
    ///   - oldToken: The old token if available.
    static func initializeAndSave(
        request: Request,
        token: RetrievedToken,
        oldToken: Self?
    ) async throws -> Self
}

extension OAuthTokenRepresentative {
    
    /// The expiration date of this token.
    private var expiryDate: Date? {
        guard let createdAt = createdAt else {
            return nil
        }
        guard self.expiresIn != 0 else {
            return .distantFuture
        }
        let errorMargin = 5
        let tokenLifetime = expiresIn  - errorMargin
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(tokenLifetime))
        return expiryDate
    }
    
    /// Whether or not this token has expired.
    var tokenHasExpired: Bool {
        guard self.expiresIn != 0,
              let expiryDate = expiryDate else {
            return false
        }
        let now = Date()
        let hasExpired = expiryDate <= now
        return hasExpired
    }
    
    /// The expiration date of this token's refresh-token.
    private var refreshTokenExpiryDate: Date? {
        guard let createdAt = createdAt else {
            return nil
        }
        guard self.refreshTokenExpiresIn != 0 else {
            return .distantFuture
        }
        let errorMargin = 5
        let tokenLifetime = refreshTokenExpiresIn - errorMargin
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(tokenLifetime))
        return expiryDate
    }
    
    /// Whether or not this token's refresh-token has expired.
    var refreshTokenHasExpired: Bool {
        guard self.refreshTokenExpiresIn != 0,
              let expiryDate = refreshTokenExpiryDate else {
            return false
        }
        let now = Date()
        let hasExpired = expiryDate <= now
        return hasExpired
    }
    
    /// Whether or not we can refresh this token.
    var isRefreshableToken: Bool {
        !self.refreshToken.isEmpty
    }
}
