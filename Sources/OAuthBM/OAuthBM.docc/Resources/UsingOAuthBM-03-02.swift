import Vapor

func setUpOAuthRoutes(app: Application) {
    
    let provider = TwitchOAuthProvider()
    
    app.get("register") { request in
        provider.requestAuthorization(
            request,
            state: .init(callbackUrl: .firstUrl)
        )
    }
}
