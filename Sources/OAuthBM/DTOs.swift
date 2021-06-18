import Vapor
import Fluent

//MARK: - RetrievedToken

/// A container that is passed to
/// `OAuthTokenRepresentative/initializeAndSave(request:token:oldToken)` to make a new token.
public struct RetrievedToken: Content {
    //MARK: Normal OAuth-2 access-token declarations
    public let accessToken: String
    public let tokenType: String
    public let scopes: [String]
    public let expiresIn: Int
    public let refreshToken: String
    public let refreshTokenExpiresIn: Int
    public let issuer: Issuer
    public let flow: Flow
    
    public enum Flow: String, Content {
        case authorizationCodeFlow
        case clientCredentialsFlow
        case webAppFlow
    }
}

extension RetrievedToken {
    /// Converts `Self` to an `OAuthToken` and saves it to db.
    public func saveToDb<Token>(req: Request, oldToken: Token?)
    -> EventLoopFuture<Token> where Token: OAuthTokenRepresentative {
        return req.eventLoop.future().tryFlatMap {
            try Token.initializeAndSave(request: req, token: self, oldToken: oldToken)
        }
    }
}

//MARK: - UserAccessToken

/// A type to decode tokens that are retrieved from providers to.
internal struct DecodedToken {
    //MARK: Normal OAuth-2 token declarations
    let accessToken: String
    let tokenType: String
    let scope: String?
    let scopes: [String]?
    let expiresIn: Int?
    let refreshToken: String?
    let refreshTokenExpiresIn: Int?
}

extension DecodedToken: Content {
    enum CodingKeys: CodingKey {
        case accessToken
        case tokenType
        case scope
        case scopes
        case expiresIn
        case refreshToken
        case refreshTokenExpiresIn
        
        var stringValue: String {
            switch self {
            case .accessToken: return "access_token"
            case .tokenType: return "token_type"
            case .scope: return "scope"
            case .scopes: return "scope"
            case .expiresIn: return "expires_in"
            case .refreshToken: return "refresh_token"
            case .refreshTokenExpiresIn: return "refresh_token_expires_in"
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.scope = try? container.decode(String.self, forKey: .scope)
        self.scopes = try? container.decode([String].self, forKey: .scopes)
        self.expiresIn = try? container.decode(Int.self, forKey: .expiresIn)
        self.refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        self.refreshTokenExpiresIn = try? container.decode(Int.self, forKey: .refreshTokenExpiresIn)
    }
}

extension DecodedToken {
    /// Converts a `DecodedToken` to a `RetrievedToken`,
    func convertToRetrievedToken(issuer: Issuer, flow: RetrievedToken.Flow) -> RetrievedToken {
        let scopesFromScope: [String]
        if let scope = self.scope {
            scopesFromScope = scope.contains(",") ?
            scope.components(separatedBy: ",") :
            scope.components(separatedBy: " ")
        } else {
            scopesFromScope = []
        }
        let scopes = scopesFromScope.isEmpty ? (self.scopes ?? []) : scopesFromScope
        return RetrievedToken(
            accessToken: self.accessToken,
            tokenType: self.tokenType,
            scopes: scopes,
            expiresIn: self.expiresIn ?? 0,
            refreshToken: self.refreshToken ?? "",
            refreshTokenExpiresIn: self.refreshTokenExpiresIn ?? 0,
            issuer: issuer,
            flow: flow
        )
    }
}
