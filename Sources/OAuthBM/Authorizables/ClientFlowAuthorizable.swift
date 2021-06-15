import Vapor

/// Protocol to enable `OAuth client credentials flow` actions
public protocol ClientFlowAuthorizable: OAuthable { }

extension ClientFlowAuthorizable {
    
    /// The request to acquire an app access token.
    ///
    /// - Throws: OAuthableError in case of error.
    private func appAccessTokenRequest() throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            client_id: self.clientId,
            client_secret: self.clientSecret,
            grant_type: "client_credentials")
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.providerTokenUrl)
        
        let queryParametersEncode: Void? = try? self.queryParametersPolicy
            .inject(parameters: queryParams, into: &clientRequest)
        guard queryParametersEncode != nil else {
            throw OAuthableError.serverError(
                status: .preconditionFailed,
                error: .queryParametersEncode(policy: queryParametersPolicy)
            )
        }
        
        return clientRequest
    }
    
    /// Tries to acquire an app access token.
    ///
    /// - Throws: OAuthableError in case of error.
    public func getAppAccessToken(_ req: Request) -> EventLoopFuture<AppAccessToken> {
        let clientRequest = req.eventLoop.tryFuture {
            try self.appAccessTokenRequest()
        }
        let clientResponse = clientRequest.flatMap {
            req.client.send($0)
        }
        let tokenContent = clientResponse.flatMap { res in
            decode(response: res, request: req, as: AppAccessToken.self)
        }
        
        return tokenContent
    }
}
