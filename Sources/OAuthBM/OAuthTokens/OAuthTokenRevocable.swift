
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
    private func revokeTokenRequest(
        accessToken: String
    ) throws -> ClientRequest {
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
    public func revokeToken(
        _ req: Request,
        accessToken: String
    ) async throws {
        let clientRequest = try self.revokeTokenRequest(accessToken: accessToken)
        let clientResponse = try await req.client.send(clientRequest).get()
        guard clientResponse.status.is200Series else {
            let error = decodeError(req: req, res: clientResponse)
            throw error
        }
    }
}
