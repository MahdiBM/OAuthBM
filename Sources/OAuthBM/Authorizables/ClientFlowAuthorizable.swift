
/// Protocol to enable `OAuth client credentials flow` actions
public protocol ClientFlowAuthorizable: OAuthable, OAuthTokenBasicAuthRequirement { }

extension ClientFlowAuthorizable {
    
    /// The client request to acquire an app access token with.
    /// - Parameter scopes: The ``OAuthable/Scopes`` to request authorization for.
    /// - Throws: ``OAuthableError``.
    /// - Returns: A `ClientRequest` to send to acquire an app access token with.
    private func appAccessTokenRequest(
        scopes: [Scopes]
    ) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            scope: joinScopes(scopes),
            grantType: .clientCredentials)
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
    
    /// Attempts to acquire an app access token.
    ///
    /// `scopes` defaults to an empty array because most providers
    /// don't require/need scopes specified for app access tokens.
    ///
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - scopes: The ``OAuthable/Scopes`` to request authorization for.
    /// - Returns: A ``RetrievedToken``.
    public func getAppAccessToken(
        _ req: Request,
        scopes: [Scopes] = []
    ) -> EventLoopFuture<RetrievedToken> {
        let clientRequest = req.eventLoop.tryFuture {
            try self.appAccessTokenRequest(scopes: scopes)
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let tokenContent = clientResponse.flatMap { res in
            decode(req: req, res: res, as: DecodedToken.self)
        }
        let retrievedToken = tokenContent.map {
            $0.convertToRetrievedToken(issuer: self.issuer, flow: .clientCredentialsFlow)
        }
        
        return retrievedToken
    }
}
