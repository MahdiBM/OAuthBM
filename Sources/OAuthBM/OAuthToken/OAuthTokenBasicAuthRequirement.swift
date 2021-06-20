import Vapor

public protocol OAuthTokenBasicAuthRequirement {
    
    /// Whether or not the request which gets the token from the provider
    /// requires basic authentication where the `username` is `clientId`
    /// and the `password` is `clientSecret`. Defaults to `false`.
    /// Majority of providers don't require this, but some provider like `Reddit` do.
    /// This should be mentioned in the provider's panel if it's required, But
    /// you may switch this to `true` if you are getting `401 Unauthorized` errors.
    var tokenRequestsRequireBasicAuthentication: Bool { get }
}

extension OAuthTokenBasicAuthRequirement where Self: OAuthable {
    
    public var tokenRequestsRequireBasicAuthentication: Bool {
        false
    }
    
    internal func injectBasicAuthHeadersIfNeeded(to clientRequest: inout ClientRequest) {
        guard self.tokenRequestsRequireBasicAuthentication else { return }
        clientRequest.headers.basicAuthorization = .init(
            username: self.clientId, password: self.clientSecret)
    }
}
