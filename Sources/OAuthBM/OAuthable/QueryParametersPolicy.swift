
/// Different ways of encoding query parameters into a request.
///
/// Some providers like `Spotify` and `Discord` don't work with `.useQueryStrings`,
/// But other providers should work ok with `.useQueryStrings`.
/// If your provider says some necessary headers/query-params are missing
/// or throws weird errors, try switching this.
public enum QueryParametersPolicy: String {
    
    /// Encodes parameters as query strings.
    case useQueryStrings
    /// Encodes parameters as url-encoded form.
    case useUrlEncodedForm
    
    /// Injects parameters into a client request.
    /// - Parameters:
    ///   - parameters: The parameters to encode into the request.
    ///   - clientRequest: The `ClientRequest` to encode parameters to.
    /// - Throws: A normal ``Vapor`` error if the encode process is unsuccessful.
    internal func inject(
        parameters: QueryParameters,
        into clientRequest: inout ClientRequest
    ) throws {
        switch self {
        case .useQueryStrings:
            try clientRequest.query.encode(parameters)
        case .useUrlEncodedForm:
            try clientRequest.content.encode(parameters, as: .urlEncodedForm)
        }
    }
}

//MARK: - ``QueryParameters`` declaration.

/// Helps encode query parameters into a request.
internal struct QueryParameters {
    
    //MARK: Stuff that might need to be passed as query params into a OAuth-2 request.
    var clientId: String?
    var clientSecret: String?
    var responseType: ResponseType?
    var redirectUri: String?
    var scope: String?
    var state: [String]?
    var grantType: GrantType?
    var refreshToken: String?
    var code: String?
    var token: String?
    
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
        func append(_ value: String?, key: CodingKeys) {
            let keyValue = (value == nil) ? nil : "\(key.rawValue)=\(value!)"
            allValues.append(keyValue)
        }
        append(self.clientId, key: .clientId)
        append(self.clientSecret, key: .clientSecret)
        append(self.responseType?.rawValue, key: .responseType)
        append(self.redirectUri, key: .redirectUri)
        append(self.scope, key: .scope)
        append(self.state?.joined(separator: ","), key: .state)
        append(self.grantType?.rawValue, key: .grantType)
        append(self.refreshToken, key: .refreshToken)
        append(self.code, key: .code)
        append(self.token, key: .token)
        
        return allValues.compactMap { $0 }
    }
    
    /// The string to be passed at the end of a url.
    ///
    /// example: "key1=value1&key2=value2&key3=value3"
    var queryString: String {
        self.queryStrings.joined(separator: "&")
    }
}

//MARK: - `Content` conformance.
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
        case token = "token"
    }
}
