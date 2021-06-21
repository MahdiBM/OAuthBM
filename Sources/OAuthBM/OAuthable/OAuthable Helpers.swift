
//MARK: - Other Declarations

extension OAuthable {
    /// All joined in a form to be used in a HTTP request.
    internal func joinScopes(_ scopes: [Scopes]) -> String {
        scopes.map(\.rawValue).joined(separator: "%20")
    }
}

//MARK: - State Validation

extension OAuthable {
    
    /// Extracts `state` from `Session` and `Request`
    /// and makes sure they are valid an match each-other.
    internal func extractAndValidateState(req: Request) throws -> State {
        let state: State
        do {
            state = try State.extract(from: req.session)
            let urlState = try State(decodeFrom: req.query)
            req.session.destroy()
            guard state == urlState
            else { throw OAuthableError.serverError(error: .invalidCookie) }
        } catch let thrownError {
            func throwError<T>(_ error: Error) -> EventLoopFuture<T> {
                req.eventLoop.future(error: error)
            }
            if let error = decodeErrorIfAvailable(req: req, res: nil) {
                throw error
            } else if let oauthableError = thrownError as? OAuthableError {
                throw oauthableError
            } else {
                throw OAuthableError.providerError(error: .unknown(error: "\(thrownError)"))
            }
        }
        
        return state
    }
}

//MARK: - Decoders

extension OAuthable {
    /// Decodes response's content while taking care of errors.
    /// - Throws: OAuthableError in case of error.
    internal func decode<T>(
        response res: ClientResponse,
        request req: Request,
        as type: T.Type
    ) -> EventLoopFuture<T> where T: Content {
        req.eventLoop.tryFuture {
            if res.status.code < 300, res.status.code >= 200 {
                do {
                    return try res.content.decode(T.self)
                } catch {
                    throw OAuthableError.serverError(
                        status: .badRequest, error: .unknown(error: "\(error)"))
                }
            } else {
                throw decodeError(req: req, res: res)
            }
        }
    }
    
    internal func decodeErrorIfAvailable(req: Request, res: ClientResponse?) -> OAuthableError? {
        if let queryError = QueryError.extractOAuthError(from: req) {
            return queryError
        } else if let res = res, let contentError = ContentError.extractOAuthError(from: res) {
            return contentError
        }
        return nil
    }
    
    internal func decodeError(req: Request, res: ClientResponse?) -> OAuthableError {
        if let error = decodeErrorIfAvailable(req: req, res: res) {
            return error
        } else if let res = res {
            return OAuthableError.providerError(
                status: res.status,
                error: .unknown(error: res.body?.contentString)
            )
        } else {
            return OAuthableError.serverError(error: .unknown(error: req.body.data?.contentString))
        }
    }
}

private struct ContentError: Decodable {
    struct MessageError: Decodable {
        let message: String
        let status: Int
    }
    
    struct ErrorError: Decodable {
        let error: String
    }
    
    static func extractOAuthError(from res: ClientResponse) -> OAuthableError? {
        func oauthError(_ providerError: OAuthableError.ProviderError) -> OAuthableError {
            .providerError(error: providerError)
        }
        if let value = try? res.content.decode(MessageError.self) {
            if let error =  OAuthableError.ProviderError(rawValue: value.message) {
                return oauthError(error)
            } else if let error = OAuthableError.ProviderError(fromDescription: value.message) {
                return oauthError(error)
            }
        } else if let value = try? res.content.decode(ErrorError.self) {
            if let error = OAuthableError.ProviderError(rawValue: value.error) {
                return oauthError(error)
            } else if let error = OAuthableError.ProviderError(fromDescription: value.error) {
                return oauthError(error)
            }
        }
        return nil
    }
}

private struct QueryError: Decodable {
    let error: String
    
    static func extractOAuthError(from req: Request) -> OAuthableError? {
        guard let value = try? req.query.decode(Self.self),
              let providerError = OAuthableError.ProviderError(rawValue: value.error)
        else { return nil }
        return OAuthableError.providerError(error: providerError)
    }
}
