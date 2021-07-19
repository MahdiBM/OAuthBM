
/// Protocol to enable token refreshments.
public protocol OAuthTokenRefreshable: OAuthable, OAuthTokenBasicAuthRequirement { }

extension OAuthTokenRefreshable {
    
    /// The client request to refresh an expired token with.
    /// - Parameter refreshToken: The refresh-token-string to make a refresh-request for.
    /// - Throws: ``OAuthableError``.
    /// - Returns: A `ClientRequest` to send to refresh a user access token with.
    private func refreshTokenRequest(
        refreshToken: String
    ) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            grantType: .refreshToken,
            refreshToken: refreshToken)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.tokenUrl)
        
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
    
    /// Immediately tries to refresh the token.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - refreshToken: The refresh-token-string to send a refresh-request for.
    /// - Returns: A fresh token.
    public func refreshToken(
        _ req: Request,
        refreshToken: String
    ) -> EventLoopFuture<RetrievedToken> {
        req.logger.trace("Will try to refresh token.", metadata: [
            "type": .string("\(Self.self)"),
            "refreshToken": .string(refreshToken),
        ])
        
        let clientRequest = req.eventLoop.tryFuture {
            try self.refreshTokenRequest(refreshToken: refreshToken)
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let refreshTokenContent = clientResponse.flatMap { res in
            decode(req: req, res: res, as: DecodedToken.self)
        }
        let retrievedToken = refreshTokenContent.map {
            $0.convertToRetrievedToken(issuer: self.issuer, flow: .authorizationCodeFlow)
        }
        return retrievedToken
    }
}
