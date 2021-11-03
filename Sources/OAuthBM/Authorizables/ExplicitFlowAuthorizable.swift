
/// Protocol to enable `OAuth authorization code flow` actions
public protocol ExplicitFlowAuthorizable: OAuthable, OAuthTokenBasicAuthRequirement { }

extension ExplicitFlowAuthorizable {
    
    //MARK: - Authorization
    
    /// The URL to redirect user to, so they are asked to give
    /// this app permissions to access their data.
    ///
    /// - Parameters:
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - scopes: The ``OAuthable/Scopes`` to request authorization for.
    /// - Returns: A URL string to redirect users to.
    private func authorizationRedirectUrl(
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases)
    ) -> String {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            responseType: .code,
            redirectUri: state.callbackUrl.rawValue,
            scope: joinScopes(scopes),
            state: state.value)
        let redirectUrl = self.authorizationUrl + "?" + queryParams.queryString
        return redirectUrl
    }
    
    /// Redirects user to the provider page where they're asked to give this app permissions.
    ///
    /// Upon successful completion, they are redirected to the `callbackUrl` and
    /// we will acquire a token with the help of the `authorizationCallback(_:)` func.
    ///
    /// - Parameters:
    ///   - req: The `Request`.
    ///   - state: The ``OAuthable/State`` of the request.
    ///   - scopes: The ``OAuthable/Scopes`` to request authorization for.
    ///   - arg: Optional extra argument to be passed to your provider for more customization.
    /// - Returns: A `Response`.
    public func requestAuthorization(
        _ req: Request,
        state: State,
        scopes: [Scopes] = Array(Scopes.allCases),
        extraArg arg: String? = nil
    ) -> Response {
        req.logger.trace("OAuth2 authorization requested.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var authUrl = self.authorizationRedirectUrl(state: state, scopes: scopes)
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
    /// - Returns: The ``OAuthable/State`` of the request and the acquired ``RetrievedToken``.
    public func authorizationCallback(
        _ req: Request
    ) async throws -> (state: State, token: RetrievedToken) {
        req.logger.trace("OAuth2 authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        
        let state = try extractAndValidateState(req: req)
        
        guard let code = req.query[String.self, at: "code"] else {
            let error = decodeError(req: req, res: nil)
            throw error
        }
        
        let clientRequest = try self.userAccessTokenRequest(
            callbackUrl: state.callbackUrl,
            code: code
        )
        let clientResponse = try await req.client.send(clientRequest).get()
        guard clientResponse.status.is200Series else {
            let error = decodeError(req: req, res: clientResponse)
            throw error
        }
        let accessTokenContent = try decode(req: req, res: clientResponse, as: DecodedToken.self)
        let retrievedToken = accessTokenContent.convertToRetrievedToken(
            issuer: self.issuer,
            flow: .authorizationCodeFlow
        )
        
        return (state: state, token: retrievedToken)
    }
    
    //MARK: - Code to Token Request
    
    /// The client request to acquire a user access token with.
    /// - Parameters:
    ///   - callbackUrl: The ``OAuthable/CallbackUrls`` to make the request for.
    ///   - code: The code-string to request authorization with.
    /// - Throws: ``OAuthableError``.
    /// - Returns: A `ClientRequest` to send to acquire a user access token with.
    private func userAccessTokenRequest(
        callbackUrl: CallbackUrls,
        code: String
    ) throws -> ClientRequest {
        let queryParams = QueryParameters.init(
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            redirectUri: callbackUrl.rawValue,
            grantType: .authorizationCode,
            code: code)
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
}

