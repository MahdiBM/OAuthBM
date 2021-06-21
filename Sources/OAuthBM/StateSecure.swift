import Vapor

/// Protocol to infer some internal implementations that
/// take care of `state` during an OAuth-2 callback.
public protocol StateSecure {
    
    /// The ``OAuthable/CallbackUrls`` type.
    associatedtype CallbackUrls: RawRepresentable
    where CallbackUrls.RawValue == String
    
    /// The ``StateContainer`` convenience typealias.
    typealias State = StateContainer<CallbackUrls>
    
    /// The function to decode errors of a request/response if available.
    ///
    /// This should be inferred from ``OAuthable`` implementations.
    func decodeErrorIfAvailable(req: Request, res: ClientResponse?) -> OAuthableError?
    
    /// Extracts `state` from `Session` and `Request`
    /// and makes sure they are valid an match each-other.
    func extractAndValidateState(req: Request) throws
}

internal extension StateSecure {
    
    /// Extracts `state` from `Session` and `Request`
    /// and makes sure they are valid an match each-other.
    func extractAndValidateState(req: Request) throws -> State {
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
