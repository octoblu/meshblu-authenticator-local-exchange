AuthController = require './controllers/auth-controller'
StaticSchemasController = require './controllers/static-schemas-controller'
class Router
  constructor: ({authService, afterAuthRedirectUrl}) ->
    throw new Error 'Missing authService' unless authService?
    throw new Error 'Missing afterAuthRedirectUrl' unless afterAuthRedirectUrl?

    @authController = new AuthController {authService, afterAuthRedirectUrl}
    @staticSchemasController = new StaticSchemasController

  route: (app) =>
    app.get '/authenticate',  @authController.signin
    app.post '/authenticate', @authController.authenticate
    app.post '/messages',     @authController.message
    app.get '/schemas/:name', @staticSchemasController.get
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
