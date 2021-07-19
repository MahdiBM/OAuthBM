import Vapor

func setUpOAuthRoutes(app: Application) {
    
    app.get("register") { request in
        TwitchOAuthProvider().requestAuthorization(
            request,
            state: .init(callbackUrl: .firstUrl)
        )
    }
}
