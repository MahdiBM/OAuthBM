import Vapor
import Fluent

//MARK: - RetrievedToken

/// A container that is passed to
/// `OAuthTokenRepresentative/initializeAndSave(request:token:oldToken)` to make a new token.
public struct RetrievedToken: Content {
    //MARK: Normal OAuth-2 access-token declarations
    public var accessToken: String
    public var tokenType: String
    public var scopes: [String]
    public var expiresIn: Int
    public var refreshToken: String
    public var refreshTokenExpiresIn: Int
    public var issuer: Issuer
    public var flow: Flow
    
    public enum Flow: String, Content {
        case authorizationCodeFlow
        case clientCredentialsFlow
        case webAppFlow
    }
}

//MARK: - AuthorizationQueryParameters

/// Parameters that are passed to callback request by the provider,
/// after a successful authorization.
struct AuthorizationQueryParameters: Content {
    public var code: String
    public var state: String
}

//MARK: - UserAccessToken

/// Access token container.
public struct UserAccessToken {
    //MARK: Normal OAuth-2 access-token declarations
    public var accessToken: String
    public var tokenType: String
    public var scope: String?
    public var scopes: [String]?
    public var expiresIn: Int
    public var refreshToken: String?
    public var refreshTokenExpiresIn: Int?
}

extension UserAccessToken: Content {
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.scope = try? container.decode(String.self, forKey: .scope)
        self.scopes = try? container.decode([String].self, forKey: .scopes)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        self.refreshTokenExpiresIn = try? container.decode(Int.self, forKey: .refreshTokenExpiresIn)
    }
}

extension UserAccessToken {
    /// Converts `self` to an `OAuthToken` and saves it to db.
    func convertToOAuthToken<Token>(
        req: Request,
        issuer: Issuer,
        flow: RetrievedToken.Flow,
        as type: Token.Type
    ) -> EventLoopFuture<Token> where Token: OAuthTokenRepresentative {
        let scopesFromScope = self.scope?.components(separatedBy: " ")
        let scopes = self.scopes ?? scopesFromScope ?? []
        let token: RetrievedToken = .init(
            accessToken: self.accessToken,
            tokenType: self.tokenType,
            scopes: scopes,
            expiresIn: self.expiresIn,
            refreshToken: self.refreshToken ?? "",
            refreshTokenExpiresIn: refreshTokenExpiresIn ?? 0,
            issuer: issuer,
            flow: flow)
        return req.eventLoop.future().tryFlatMap {
            try Token.initializeAndSave(request: req, token: token, oldToken: nil)
        }
    }
}

//MARK: - UserRefreshToken

/// Refresh token container.
public struct UserRefreshToken {
    //MARK: Normal OAuth-2 refresh-token declarations
    public var accessToken: String
    public var tokenType: String
    public var scope: String?
    public var scopes: [String]?
    public var expiresIn: Int
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

extension UserRefreshToken {
    /// Makes a new token with refreshed info and saves it to db.
    /// - Parameter oldToken: The expired token.
    func makeNewOAuthToken<Token>(req: Request, flow: RetrievedToken.Flow, oldToken: Token)
    -> EventLoopFuture<Token> where Token: OAuthTokenRepresentative {
        let scopesFromScope: [String]
        if let scope = self.scope {
            scopesFromScope = scope.contains(",") ?
                scope.components(separatedBy: ",") :
                scope.components(separatedBy: " ")
        } else {
            scopesFromScope = []
        }
        let scopes = self.scopes ?? scopesFromScope
        let refreshTokenExpiresIn: Int
        if oldToken.refreshTokenExpiresIn != 0,
           let oldCreatedAt = oldToken.createdAt {
            refreshTokenExpiresIn = oldToken.refreshTokenExpiresIn
            + Int(oldCreatedAt.timeIntervalSinceNow.rounded(.down))
        } else {
            refreshTokenExpiresIn = 0
        }
        let token: RetrievedToken = .init(
            accessToken: self.accessToken,
            tokenType: self.tokenType,
            scopes: scopes,
            expiresIn: self.expiresIn,
            refreshToken: oldToken.refreshToken,
            refreshTokenExpiresIn: refreshTokenExpiresIn,
            issuer: oldToken.issuer,
            flow: flow)
        return req.eventLoop.future().tryFlatMap {
            try Token.initializeAndSave(request: req, token: token, oldToken: oldToken)
        }
    }
}

//MARK: - AppAccessToken

/// App access-token container.
public struct AppAccessToken: Content {
    public var accessToken: String
    public var expiresIn: Int
    public var tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
