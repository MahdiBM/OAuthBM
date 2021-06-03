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
struct QueryParameters: Content {
    //MARK: Stuff that might need to be passed as query params into a OAuth-2 request.
    var client_id: String?
    var client_secret: String?
    var response_type: String?
    var redirect_uri: String?
    var scope: String?
    var state: String?
    var grant_type: String?
    var refresh_token: String?
    var code: String?
    
    /// The pairs of key-values that can be passed into the url.
    /// 
    /// example: ["key1=value1", "key2=value2"]
    private var queryStrings: [String] {
        var allValues = [String?]()
        func append(value: String?, key: String) {
            let keyValue = (value == nil) ? nil : "\(key)=\(value!)"
            allValues.append(keyValue)
        }
        append(value: self.client_id, key: "client_id")
        append(value: self.client_secret, key: "client_secret")
        append(value: self.response_type, key: "response_type")
        append(value: self.redirect_uri, key: "redirect_uri")
        append(value: self.scope, key: "scope")
        append(value: self.state, key: "state")
        append(value: self.grant_type, key: "grant_type")
        append(value: self.refresh_token, key: "refresh_token")
        append(value: self.code, key: "code")
        
        return allValues.compactMap { $0 }
    }
    
    /// The string to be passed at the end of a url.
    ///
    /// example: "key1=value1&key2=value2&key3=value3"
    var queryString: String {
        self.queryStrings.joined(separator: "&")
    }
}
