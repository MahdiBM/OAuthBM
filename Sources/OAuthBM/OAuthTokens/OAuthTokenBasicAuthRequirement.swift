
/// Indicates whether or not an OAuth-2 provider requires basic authorization where applicable.
public protocol OAuthTokenBasicAuthRequirement {
    
    /// Whether or not the request which gets the token from the provider
    /// requires basic authentication.
    ///
    /// Defaults to `false`.
    /// The basic authorization `username` will be the `clientId` and the `password`
    /// will be the `clientSecret`.
    /// Majority of providers don't require this, but some provider like `Reddit` do.
    /// This should be mentioned in the provider's panel if it's required, But
    /// you may switch this to `true` if you are getting `401 Unauthorized` errors.
    var tokenRequestsRequireBasicAuthentication: Bool { get }
}

extension OAuthTokenBasicAuthRequirement where Self: OAuthable {
    
    public var tokenRequestsRequireBasicAuthentication: Bool {
        false
    }
    
    /// Injects basic authorization headers to the request if needed.
    /// - Parameter clientRequest: The `ClientRequest` to inject to.
    internal func injectBasicAuthHeadersIfNeeded(to clientRequest: inout ClientRequest) {
        guard self.tokenRequestsRequireBasicAuthentication else { return }
        clientRequest.headers.basicAuthorization = .init(
            username: self.clientId, password: self.clientSecret)
    }
}
