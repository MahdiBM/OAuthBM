import Vapor

/// Different ways of encoding query parameters into a request.
///
/// Some providers like `Spotify` don't work with `.passInUrl`,
/// But most providers should work well with `.passInUrl`.
/// If your provider says some necessary headers/query-params
/// are missing, then you should try `.useUrlEncodedForm`.
public enum QueryParametersPolicy: String {
    /// Encodes parameters as query strings.
    case passInUrl
    /// Encodes parameters as url-encoded form.
    case useUrlEncodedForm
    
    /// The value to use if you are unsure.
    static let `default` = Self.passInUrl
    
    /// Injects parameters into a client request.
    internal func inject(
        parameters: QueryParameters,
        into clientRequest: inout ClientRequest
    ) throws {
        switch self {
        case .passInUrl:
            try clientRequest.query.encode(parameters)
        case .useUrlEncodedForm:
            try clientRequest.content.encode(parameters, as: .urlEncodedForm)
        }
    }
}

/// Helps encode query parameters into a request.
internal struct QueryParameters {
    //MARK: Stuff that might need to be passed as query params into a OAuth-2 request.
    var clientId: String?
    var clientSecret: String?
    var responseType: ResponseType?
    var redirectUri: String?
    var scope: String?
    var state: String?
    var grantType: GrantType?
    var refreshToken: String?
    var code: String?
    
    /// The `response_type` of OAuth requests.
    enum ResponseType: String, Content {
        case token = "token"
        case code = "code"
    }
    
    /// The `grant_type` of OAuth requests.
    enum GrantType: String, Content {
        case clientCredentials = "client_credentials"
        case authorizationCode = "authorization_code"
        case refreshToken = "refresh_token"
    }
    
    /// The pairs of key-values that can be passed into the url.
    /// 
    /// example: ["key1=value1", "key2=value2"]
    private var queryStrings: [String] {
        var allValues = [String?]()
        func append(value: String?, key: CodingKeys) {
            let keyValue = (value == nil) ? nil : "\(key.rawValue)=\(value!)"
            allValues.append(keyValue)
        }
        append(value: self.clientId, key: .clientId)
        append(value: self.clientSecret, key: .clientSecret)
        append(value: self.responseType?.rawValue, key: .responseType)
        append(value: self.redirectUri, key: .redirectUri)
        append(value: self.scope, key: .scope)
        append(value: self.state, key: .state)
        append(value: self.grantType?.rawValue, key: .grantType)
        append(value: self.refreshToken, key: .refreshToken)
        append(value: self.code, key: .code)
        
        return allValues.compactMap { $0 }
    }
    
    /// The string to be passed at the end of a url.
    ///
    /// example: "key1=value1&key2=value2&key3=value3"
    var queryString: String {
        self.queryStrings.joined(separator: "&")
    }
}

extension QueryParameters: Content {
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case responseType = "response_type"
        case redirectUri = "redirect_uri"
        case scope = "scope"
        case state = "state"
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case code = "code"
    }
}
