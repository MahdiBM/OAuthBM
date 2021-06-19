import Vapor

/// Protocol to enable token revocations.
public protocol OAuthTokenRevocable: OAuthable {
    
    /// Provider's endpoint to revoke access tokens with.
    var revocationUrl: String { get }
}

extension OAuthTokenRevocable {
    
    /// The request to revoke a token with.
    ///
    /// - Throws: OAuthableError in case of error.
    private func revokeTokenRequest(accessToken: String) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            token: accessToken)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.revocationUrl)
        
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
    
    /// Immediately tries to revoke the token.
    ///
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A Void signal indicating success.
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
