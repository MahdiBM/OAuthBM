import Fluent
import Vapor

public protocol OAuthTokenRepresentable {
    var accessToken: String { get set }
    var refreshToken: String { get set }
    var expiresIn: Int { get set }
    var scopes: [String] { get set }
    var tokenType: String { get set }
    var issuer: Issuer { get set }
    var createdAt: Date? { get }
    
    static func initialize(req: Request, token: RetrievedToken, oldToken: Self?)
    throws -> EventLoopFuture<Self>
}

extension OAuthTokenRepresentable {
    var expiryDate: Date? {
        guard let createdAt = createdAt else {
            return nil
        }
        let errorMargin = 5
        let tokenLifeLength = expiresIn  - errorMargin
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(tokenLifeLength))
        return expiryDate
    }
    
    var hasExpired: Bool {
        guard let expiryDate = expiryDate else {
            return false
        }
        let now = Date()
        let hasExpired = expiryDate <= now
        return hasExpired == true
    }
}
