
/// Errors that can be thrown by OAuthable's declarations.
public enum OAuthableError: AbortError {
    
    /// Errors thrown by the provider.
    case providerError(status: HTTPStatus = .badRequest, error: ProviderError)
    
    /// Errors thrown by the server.
    case serverError(status: HTTPStatus = .badRequest, error: ServerError)
    
    /// Reason for this error.
    public var reason: String {
        switch self {
        case let .providerError(_, error):
            return "Provider failed. Error: \(error.errorDescription)"
        case let .serverError(_, error):
            return "Server failed. Error: \(error.errorDescription)"
        }
    }
    
    /// Status code of the error.
    public var status: HTTPResponseStatus {
        switch self {
        case .providerError(let status, _): return status
        case .serverError(let status, _): return status
        }
    }
}

/// Equatable Conformance.
extension OAuthableError: Equatable {
    public static func == (lhs: OAuthableError, rhs: OAuthableError) -> Bool {
        lhs.reason == rhs.reason
    }
}

//MARK: - ServerError

extension OAuthableError {
    public enum ServerError: Equatable {
        case invalidCookie
        case stateDecode(state: String)
        case queryParametersEncode(policy: QueryParametersPolicy)
        case unknown(error: String?)
        
        fileprivate var errorDescription: String {
            switch self {
            case .invalidCookie:
                return "[Could not approve the legitimacy of your request. Please use a web"
                    + " browser that allows cookies (e.g. Google Chrome, Firefox, Microsoft Edge)"
                    + " , or enable cookies for this website.]"
            case .stateDecode(let state):
                return "[Could not decode state \(state.debugDescription).]"
            case .queryParametersEncode(let policy):
                return "[Failed to encode query parameters into"
                    + " the request using policy `\(policy.rawValue)`.]"
            case .unknown(let error): return "[UNKNOWN: \(error ?? "NIL")]"
            }
        }
        
    }
}

//MARK: - ProviderError

extension OAuthableError {
    public enum ProviderError: Equatable {
        case unsupportedOverHttp
        case versionRejected
        case parameterAbsent
        case parameterRejected
        case invalidClient
        case invalidRequest
        case unsupportedResponseType
        case unsupportedGrantType
        case invalidParam
        case unauthorizedClient
        case accessDenied
        case serverError
        case tokenExpired
        case invalidToken
        case invalidCallback
        case invalidClientSecret
        case invalidGrant
        case invalidScope
        case unknown(error: String?)
        
        private var rawValue: String {
            switch self {
            case .unsupportedOverHttp: return "unsupported_over_http"
            case .versionRejected: return "version_rejected"
            case .parameterAbsent: return "parameter_absent"
            case .parameterRejected: return "parameter_rejected"
            case .invalidClient: return "invalid_client"
            case .invalidRequest: return "invalid_request"
            case .unsupportedResponseType: return "unsupported_response_type"
            case .unsupportedGrantType: return "unsupported_grant_type"
            case .invalidParam: return "invalid_param"
            case .unauthorizedClient: return "unauthorized_client"
            case .accessDenied: return "access_denied"
            case .serverError: return "server_error"
            case .tokenExpired: return "token_expired"
            case .invalidToken: return "invalid_token"
            case .invalidCallback: return "invalid_callback"
            case .invalidClientSecret: return "invalid_client_secret"
            case .invalidGrant: return "invalid_grant"
            case .invalidScope: return "invalid_scope"
            case .unknown: return ""
            }
        }
        
        private static let allCases: [Self] = [
            .unsupportedOverHttp,
            .versionRejected,
            .parameterAbsent,
            .parameterRejected,
            .invalidClient,
            .invalidRequest,
            .unsupportedResponseType,
            .unsupportedGrantType,
            .invalidParam,
            .unauthorizedClient,
            .accessDenied,
            .serverError,
            .tokenExpired,
            .invalidToken,
            .invalidCallback,
            .invalidClientSecret,
            .invalidGrant,
            .invalidScope,
            .unknown(error: ""),
        ]
        
        private var description: String {
            switch self {
            case .unsupportedOverHttp:
                return "OAuth 2.0 only supports the calls over https"
            case .versionRejected:
                return "An unsupported version of OAuth was supplied"
            case .parameterAbsent:
                return "A required parameter is missing from the request"
            case .parameterRejected:
                return "A parameter was too long"
            case .invalidClient:
                return "An invalid client ID was given"
            case .invalidRequest:
                return "An invalid request parameter was given"
            case .unsupportedResponseType:
                return "The provided response type does not match the request"
            case .unsupportedGrantType:
                return "The provided grant type does not match the request"
            case .invalidParam:
                return "An invalid request parameter was provided"
            case .unauthorizedClient:
                return "The client is not given permissions to perform this action"
            case .accessDenied:
                return "The resource owner refused the request for authorization"
            case .serverError:
                return "An unexpected error happened"
            case .tokenExpired:
                return "The provided token has expired"
            case .invalidToken:
                return "The provided token was invalid"
            case .invalidCallback:
                return "The provided callback URI does not match the consumer key"
            case .invalidClientSecret:
                return "The provided client secret is invalid"
            case .invalidGrant:
                return "The provided token has either expired or is invalid"
            case .invalidScope:
                return "The requested scope is invalid, unknown, or malformed"
            case .unknown(let error): return "UNKNOWN: " + (error ?? "NIL")
            }
        }
        
        fileprivate var errorDescription: String {
            switch self {
            case .unknown(let errorString): return "[UNKNOWN: \(errorString ?? "NIL")]"
            default: return "[error: \(self.rawValue), description: \(self.description)]"
            }
        }
        
        init? (rawValue: String) {
            guard !rawValue.replacingOccurrences(of: " ", with: "").isEmpty,
                  let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            else { return nil }
            self = value
        }
        
        init? (fromDescription desc: String) {
            guard let value = Self.allCases.first(where: { $0.description.contains(desc) })
            else { return nil }
            self = value
        }
    }
}
