import Vapor

func setUpOAuthRoutes(app: Application) {
    
    app.get("register") { request in
        TwitchOAuthProvider().requestAuthorization(
            request,
            state: .init(callbackUrl: .firstUrl)
        )
    }
    
    app.get("authorization", "callback") { request in
        TwitchOAuthProvider().authorizationCallback(request).flatMapAlways {
            result in
            switch result {
            case let .success(state, token):
                // Finish the authorization process and
                // show a "successful signup" message to your user.
            case let .failure(error):
                // Authorization has been unsuccessful, finish the process and
                // show an "unsuccessful signup" message to your user.
            }
        }
    }
}
