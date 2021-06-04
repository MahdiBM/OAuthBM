### Step 1: Setup prerequisites
* `OAuthBM` uses Sessions to store cookie-related data. Make sure you have Sessions ready by [reading the official Vapor docs](https://docs.vapor.codes/4.0/sessions/).

### Step 2: Warming up

**Here i'll assume you want `OAuthBM` to take of the tokens for you, and you are using the `OAuth authorization code flow`; as those two are the most common.**    
**`OAuthBM` can also work without fluent and with both `OAuth implicit code flow` and `OAuth client credentials flow`.**

* First make sure you have a table conforming to `OAuthTokenRepresentable`, `Model` and `Content` ready. You can find an example [here in tests](/Tests/OAuthBMTests/Preperation/OAuthTokens%20Table.swift).   
As described in the documentations around [the `OAuthTokenRepresentable` protocol](/Sources/OAuthBM/OAuthTokenRepresentable.swift), the `initialize(req:token:oldToken:) -> ELF<Self>` func is just an initializer that gives you more flexibility than a normal `init`,
Meaning that you can take care of everything that is needed before a token is made, then `init` that token and pass it to `OAuthBM`.     
You don't need to save the token into the database as `OAuthBM` will do that for you.
* Make a type conforming to `OAuthable` and `OAuthTokenConvertible`. This type will be where you enter your provider's info.    
Read [OAuthable's comments](/Sources/OAuthBM/OAuthable.swift) and take a look at [this example from tests](/Tests/OAuthBMTests/Preperation/TestProvider.swift) to have a feeling about what you should be doing.

### Step 3: Setup your routes

- Now you need to setup 2 routes. One for when users want to register, and one as the callback url which your provider will redirect your users to, after they give/dont-give your app premissions.    
- What happens is, after hitting the register route, your users are redirected to your provider where they are asked to give you premissions, then they are reidrected back to your callback endpoint.   
The `authorizationCallback(_:)` func which you'll call in your callback endpoint will take care of everything and output the `state` and `token` to you so you can finish the job and send an appropriate message to your users.   
- For examples, you can take a look [this file](/Tests/OAuthBMTests/OAuthBMTests.swift) in tests where the two routes are set-up.  
