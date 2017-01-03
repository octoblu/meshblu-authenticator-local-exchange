AuthController          = require './controllers/auth-controller'
HealthcheckController   = require './controllers/healthcheck-controller'
StaticSchemasController = require './controllers/static-schemas-controller'

class Router
  constructor: ({authService, afterAuthRedirectUrl, healthcheckService}) ->
    throw new Error 'Missing authService' unless authService?
    throw new Error 'Missing afterAuthRedirectUrl' unless afterAuthRedirectUrl?
    throw new Error 'Missing healthcheckService' unless healthcheckService?

    @authController = new AuthController {authService, afterAuthRedirectUrl}
    @healthcheckController = new HealthcheckController {healthcheckService}
    @staticSchemasController = new StaticSchemasController

  route: (app) =>
    app.get '/authenticate',  @authController.signin
    app.post '/authenticate', @authController.authenticate
    app.post '/messages',     @authController.message
    app.get '/schemas/:name', @staticSchemasController.get
    app.get '/proofoflife',   @healthcheckController.get
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
