
//MARK: - Default Values

public extension OAuthable {
    
    var queryParametersPolicy: Policy {
        .useUrlEncodedForm
    }
}

//MARK: - Other Declarations

extension OAuthable {
    
    /// ``OAuthable/Scopes`` joined in a form to be used in a HTTP request.
    internal func joinScopes(_ scopes: [Scopes]) -> String {
        scopes.map(\.rawValue).joined(separator: "%20")
    }
}

//MARK: - State Validation

extension OAuthable {
    
    /// Extracts ``OAuthable/State`` from `Session` and `Request`
    /// and makes sure they are valid and match each-other.
    internal func extractAndValidateState(req: Request) throws -> State {
        let state: State
        do {
            state = try State.extract(from: req.session)
            let urlState = try State(decodeFrom: req.query)
            req.session.destroy()
            guard state == urlState
            else { throw OAuthableError.serverError(error: .invalidCookies) }
        } catch let thrownError {
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
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - res: The `ClientResponse`.
    ///   - type: The type to decode to.
    /// - Returns: An `EventLoopFuture` containing a value of the entered type.
    internal func decode<T>(req: Request, res: ClientResponse, as type: T.Type)
    -> EventLoopFuture<T> where T: Content {
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
    
    /// Decodes any available errors.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - res: The `ClientResponse` if available.
    /// - Returns: ``OAuthableError`` if there are any errors, and `nil` otherwise.
    internal func decodeErrorIfAvailable(req: Request, res: ClientResponse?) -> OAuthableError? {
        if let queryError = QueryError.extractOAuthError(from: req) {
            return queryError
        } else if let res = res, let contentError = ContentError.extractOAuthError(from: res) {
            return contentError
        }
        return nil
    }
    
    /// Decodes any available errors; Throws an `unknown` error if none are available.
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - res: The `ClientResponse` if available.
    /// - Returns: An ``OAuthableError``.
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
    
    /// Extracts a possible errors out of a `ClientResponse`
    /// - Parameter res: The `ClientResponse`.
    /// - Returns: ``OAuthableError`` if there are any errors, and `nil` otherwise.
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
    
    /// Extracts a possible errors out of a `Request`
    /// - Parameter req: The `Request`.
    /// - Returns: ``OAuthableError`` if there are any errors, and `nil` otherwise.
    static func extractOAuthError(from req: Request) -> OAuthableError? {
        guard let value = try? req.query.decode(Self.self),
              let providerError = OAuthableError.ProviderError(rawValue: value.error)
        else { return nil }
        return OAuthableError.providerError(error: providerError)
    }
}
