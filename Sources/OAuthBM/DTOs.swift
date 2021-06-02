import Vapor

/// A container that is passed to the `initialize` func of
/// the `OAuthTokenRepresentable` protocol to make a new token.
public struct RetrievedToken {
    var accessToken: String
    var tokenType: String
    var scopes: [String]
    var expiresIn: Int
    var refreshToken: String
    var issuer: Issuer
}

/// Parameters that are passed to callback request by the provider,
/// after a successful authorization.
struct AuthorizationQueryParameters: Content {
    var code: String
    var state: String
}

/// Access token container.
public struct UserAccessToken {
    var accessToken: String
    var tokenType: String
    var scope: String?
    var scopes: [String]?
    var expiresIn: Int
    var refreshToken: String
}

extension UserAccessToken: Content {
    enum CodingKeys: CodingKey {
        case accessToken
        case tokenType
        case scope
        case scopes
        case expiresIn
        case refreshToken
        
        var stringValue: String {
            switch self {
            case .accessToken: return "access_token"
            case .tokenType: return "token_type"
            case .scope: return "scope"
            case .scopes: return "scope"
            case .expiresIn: return "expires_in"
            case .refreshToken: return "refresh_token"
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.scope = try? container.decode(String.self, forKey: .scope)
        self.scopes = try? container.decode([String].self, forKey: .scopes)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
    }
}

    
/// Refresh token container.
public struct UserRefreshToken {
    var accessToken: String
    var tokenType: String
    var scope: String?
    var scopes: [String]?
    var expiresIn: Int
}


extension UserRefreshToken: Content {
    enum CodingKeys: CodingKey {
        case accessToken
        case tokenType
        case scope
        case scopes
        case expiresIn
        
        var stringValue: String {
            switch self {
            case .accessToken: return "access_token"
            case .tokenType: return "token_type"
            case .scope: return "scope"
            case .scopes: return "scope"
            case .expiresIn: return "expires_in"
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.scope = try? container.decode(String.self, forKey: .scope)
        self.scopes = try? container.decode([String].self, forKey: .scopes)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
    }
}


/// App access-token container.
struct AppAccessToken: Content {
    var accessToken: String
    var expiresIn: Int
    var tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

extension UserAccessToken {
    /// Converts `self` to an `OAuthTokens`.
    func convertToOAuthToken<Token>(req: Request, issuer: Issuer, as type: Token.Type)
    -> EventLoopFuture<Token> where Token: OAuthTokenRepresentable {
        let scopesFromScope = self.scope?.components(separatedBy: " ")
        let scopes = self.scopes ?? scopesFromScope ?? []
        let token: RetrievedToken = .init(
            accessToken: self.accessToken,
            tokenType: self.tokenType,
            scopes: scopes,
            expiresIn: self.expiresIn,
            refreshToken: self.refreshToken,
            issuer: issuer)
        return req.eventLoop.future().tryFlatMap {
            try Token.initialize(req: req, token: token, oldToken: nil)
        }
    }
}

extension UserRefreshToken {
    /// Makes a new token with refreshed info.
    /// - Parameter oldToken: The expired token.
    func makeNewOAuthToken<Token>(req: Request, oldToken: Token)
    -> EventLoopFuture<Token> where Token: OAuthTokenRepresentable {
        let scopesFromScope = self.scope?.components(separatedBy: " ")
        let scopes = self.scopes ?? scopesFromScope ?? []
        let token: RetrievedToken = .init(
            accessToken: self.accessToken,
            tokenType: self.tokenType,
            scopes: scopes,
            expiresIn: self.expiresIn,
            refreshToken: oldToken.refreshToken,
            issuer: oldToken.issuer)
        return req.eventLoop.future().tryFlatMap {
            try Token.initialize(req: req, token: token, oldToken: oldToken)
        }
    }
}
