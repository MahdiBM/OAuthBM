import Vapor

// ExplicitFlowAuthorizable + OAuthTokenConvertible

public extension ExplicitFlowAuthorizable where Self: OAuthTokenConvertible {

    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    ///
    /// - Throws: OAuthableError in case of error.
    func authorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: State, token: Token)> {
        req.logger.trace("OAuth2 authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var oauthable: some ExplicitFlowAuthorizable { self }
        return oauthable.authorizationCallback(req).flatMap { state, accessToken in
            accessToken.convertToOAuthToken(
                req: req,
                issuer: self.issuer,
                flow: .clientCredentialsFlow,
                as: Token.self
            ).map({ (state: state as! State, token: $0) })
        }
    }
    
    /// Immediately tries to refresh the token.
    ///
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    func renewToken(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        var oauthable: some ExplicitFlowAuthorizable { self }
        let refreshTokenContent = oauthable
            .renewToken(req, refreshToken: token.refreshToken)
        let removeTokenIfRevoked = refreshTokenContent.flatMapAlways {
            result -> EventLoopFuture<UserRefreshToken> in
            switch result {
            case let .success(token): return req.eventLoop.future(token)
            case let .failure(error):
                if let error = error as? OAuthableError,
                   error == .providerError(status: .badRequest, error: .invalidToken) {
                    /// Delete the token if its been revoked.
                    return token.delete(on: req.db)
                        .flatMapThrowing({ throw error })
                } else {
                    return req.eventLoop.future(error: error)
                }
            }
        }
        let newToken = removeTokenIfRevoked.flatMap { refreshToken in
            refreshToken.makeNewOAuthToken(req: req, flow: .authorizationCodeFlow, oldToken: token)
        }
        let deleteOldToken = newToken.flatMap { newToken in
            token.delete(on: req.db).map { _ in newToken }
        }
        
        return deleteOldToken.map { $0 }
    }
    
    /// Renew's the token if needed.
    ///
    /// - Returns: The same token if not expired, otherwise a fresh token.
    func renewTokenIfExpired(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        if token.tokenHasExpired {
            req.logger.trace("Token has expired. Will try to acquire new one.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return renewToken(req, token: token)
        } else {
            req.logger.trace("Token has not expired. Will return the current token.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return req.eventLoop.future(token)
        }
    }
}

// ClientFlowAuthorizable + OAuthTokenConvertible

public extension ClientFlowAuthorizable where Self: OAuthTokenConvertible {
    /// Tries to acquire an app access token.
    ///
    /// - Throws: OAuthableError in case of error.
    func getAppAccessToken(_ req: Request) -> EventLoopFuture<Token> {
        
        var oauthable: some ClientFlowAuthorizable { self }
        let appAccessToken = oauthable.getAppAccessToken(req)
        let retrievedToken = appAccessToken.map { token in
            RetrievedToken(
                accessToken: token.accessToken,
                tokenType: token.tokenType,
                scopes: Self.Scopes.allCases.map({ $0.rawValue }),
                expiresIn: token.expiresIn,
                refreshToken: "",
                refreshTokenExpiresIn: 0,
                issuer: self.issuer,
                flow: .clientCredentialsFlow
            )
        }
        let oauthToken = retrievedToken.tryFlatMap { token in
            try Token.initializeAndSave(request: req, token: token, oldToken: nil)
        }
        
        return oauthToken
    }
}

// WebAppFlowAuthorizable + OAuthTokenConvertible

public extension WebAppFlowAuthorizable where Self: OAuthTokenConvertible {
    
    /// Takes care of callback endpoint's actions,
    /// after the user hits the authorization endpoint
    /// and gets redirected back to this app by the provider.
    ///
    /// - Throws: OAuthableError in case of error.
    func webAppAuthorizationCallback(_ req: Request)
    -> EventLoopFuture<(state: State, token: Token)> {
        req.logger.trace("OAuth2 web app authorization callback called.", metadata: [
            "type": .string("\(Self.self)")
        ])
        var oauthable: some WebAppFlowAuthorizable { self }
        return oauthable.webAppAuthorizationCallback(req).flatMap { state, accessToken in
            accessToken.convertToOAuthToken(
                req: req,
                issuer: self.issuer,
                flow: .webAppFlow,
                as: Token.self
            ).map({ (state: state as! State, token: $0) })
        }
    }
    
    /// Immediately tries to refresh the token.
    ///
    /// - Throws: OAuthableError in case of error.
    /// - Returns: A fresh token.
    func renewWebAppToken(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        var oauthable: some WebAppFlowAuthorizable { self }
        let refreshTokenContent = oauthable
            .renewWebAppToken(req, refreshToken: token.refreshToken)
        let removeTokenIfRevoked = refreshTokenContent.flatMapAlways {
            result -> EventLoopFuture<UserRefreshToken> in
            switch result {
            case let .success(token): return req.eventLoop.future(token)
            case let .failure(error):
                if let error = error as? OAuthableError,
                   error == .providerError(status: .badRequest, error: .invalidToken) {
                    /// Delete the token if its been revoked.
                    return token.delete(on: req.db)
                        .flatMapThrowing({ throw error })
                } else {
                    return req.eventLoop.future(error: error)
                }
            }
        }
        let newToken = removeTokenIfRevoked.flatMap { refreshToken in
            refreshToken.makeNewOAuthToken(req: req, flow: .webAppFlow, oldToken: token)
        }
        let deleteOldToken = newToken.flatMap { newToken in
            token.delete(on: req.db).map { _ in newToken }
        }
        
        return deleteOldToken.map { $0 }
    }
    
    /// Renew's the token if needed.
    ///
    /// - Returns: The same token if not expired, otherwise a fresh token.
    func renewWebAppTokenIfExpired(_ req: Request, token: Token) -> EventLoopFuture<Token> {
        if token.tokenHasExpired {
            req.logger.trace("Token has expired. Will try to acquire new one.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return renewWebAppToken(req, token: token)
        } else {
            req.logger.trace("Token has not expired. Will return the current token.", metadata: [
                "type": .string("\(Self.self)"),
                "token": .stringConvertible(token),
            ])
            return req.eventLoop.future(token)
        }
    }
}
