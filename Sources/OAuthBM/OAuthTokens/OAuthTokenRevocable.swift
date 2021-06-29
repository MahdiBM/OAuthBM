
/// Protocol to enable token revocations.
public protocol OAuthTokenRevocable: OAuthable, OAuthTokenBasicAuthRequirement {
    
    /// Provider's endpoint to revoke access tokens with.
    var revocationUrl: String { get }
}

extension OAuthTokenRevocable {
    
    /// The client request to revoke a token with.
    /// - Parameter accessToken: The access-token-string to revoke.
    /// - Throws: ``OAuthableError``.
    /// - Returns: A `ClientRequest` to send to revoke a token with.
    private func revokeTokenRequest(accessToken: String) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            token: accessToken)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.revocationUrl)
        
        injectBasicAuthHeadersIfNeeded(to: &clientRequest)
        do {
            try self.queryParametersPolicy.inject(parameters: queryParams, into: &clientRequest)
        } catch {
            throw OAuthableError.serverError(
                status: .preconditionFailed,
                error: .queryParametersEncode(policy: queryParametersPolicy)
            )
        }
        
        return clientRequest
    }
    
    /// Immediately tries to revoke the token.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - accessToken: The access-token-string to revoke.
    /// - Returns: A `Void` signal indicating success.
    public func revokeToken(_ req: Request, accessToken: String) -> EventLoopFuture<Void> {
        let clientRequest = req.eventLoop.tryFuture {
            try self.revokeTokenRequest(accessToken: accessToken)
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let errorsHandled = clientResponse.flatMapAlways {
            result -> EventLoopFuture<Void> in
            switch result {
            case let .success(response):
                switch response.status {
                case .ok: return req.eventLoop.future()
                default:
                    let error = decodeError(req: req, res: response)
                    return req.eventLoop.future(error: error)
                }
            case let .failure(error):
                return req.eventLoop.future(error: error)
            }
        }
        
        return errorsHandled
    }
}
