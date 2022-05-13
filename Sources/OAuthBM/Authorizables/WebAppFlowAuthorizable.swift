
/// Protocol to enable `OAuth web application flow` actions
public protocol WebAppFlowAuthorizable: OAuthable { }

extension WebAppFlowAuthorizable {
    
    //MARK: - Authorization
    
    /// The URL to redirect user to, so they are asked to give
    /// this app permissions to access their data.
    ///
    /// - Parameters:
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - scopes: The ``OAuthable/Scopes`` to request authorization for.
    /// - Returns: A URL string to redirect users to.
    private func webAppAuthorizationRedirectUrl(
        state: State
    ) -> String {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            redirectUri: state.callbackUrl.rawValue,
            state: state.value)
        let redirectUrl = self.authorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// Upon successful completion, they are redirected to the `self.callbackUrl` and
    /// we will acquire a token with the help of the `authorizationCallback(_:)` func.
    ///
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - arg: Optional extra argument to be passed to your provider for more customization.
    /// - Returns: A `Response`.
    public func requestWebAppAuthorization(
        _ req: Request,
        state: State,
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.debug("OAuth2 web app authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authUrl = self.webAppAuthorizationRedirectUrl(state: state)
        if let arg = arg {
            authUrl = authUrl + "&" + arg
        }
        state.injectTo(session: req.session)
        return req.redirect(to: authUrl)
    }
    
    /// Takes care of callback endpoint's actions.
    ///
    /// This func is used after the user gets redirected back to this app by the provider.
    ///
    /// - Parameter req: The `Request`.
    /// - Returns: The ``OAuthable/State`` of the request.
    public func webAppAuthorizationCallback(
        _ req: Request
    ) async throws -> (state: State, token: RetrievedToken) {
        req.logger.debug("OAuth2 web app authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        
        let state = try extractAndValidateState(req: req)
        
        guard let code = req.query[String.self, at: "code"] else {
            let error = decodeError(req: req, res: nil)
            throw error
        }
        
        let clientRequest = try webAppAccessTokenRequest(state: state, code: code)
        let clientResponse = try await req.client.send(clientRequest)
        guard clientResponse.status.is200Series else {
            let error = decodeError(req: req, res: clientResponse)
            throw error
        }
        let accessTokenContent = try decode(req: req, res: clientResponse, as: DecodedToken.self)
        let retrievedToken = accessTokenContent.convertToRetrievedToken(
            issuer: self.issuer,
            flow: .webAppFlow
        )
        
        return (state: state, token: retrievedToken)
    }
    
    //MARK: - Code to Token Request
    
    /// The request that gets an access token from the provider,
    /// using the `code` that this app should acquired after
    /// user being redirected to this app by the provider.
    /// - Parameters:
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - code: The code-string to request authorization with.
    /// - Throws: ``OAuthableError``.
    /// - Returns: A `ClientRequest` to send to acquire a web-app access token with.
    private func webAppAccessTokenRequest(
        state: State,
        code: String
    ) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            redirectUri: state.callbackUrl.rawValue,
            state: state.value,
            code: code)
        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = .init(string: self.tokenUrl)
        
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
}
