import Vapor

func setUpOAuthRoutes(app: Application) {
    
    let provider = TwitchOAuthProvider()
    
    app.get("register") { request in
        provider.requestAuthorization(
            request,
            state: .init(callbackUrl: .firstUrl)
        )
    }
    
    app.get("authorization", "callback") { request in
        do {
            let (state, oauthToken) = try await provider
                .authorizationCallbackWithOAuthToken(request)
            
            // Finish the authorization process and
            // show a "successful signup" message to your user.
        } catch let error {
            
            // Authorization has been unsuccessful, finish the process and
            // show an "unsuccessful signup" message to your user.
        }
    }
}
