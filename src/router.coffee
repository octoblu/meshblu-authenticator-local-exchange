MeshbluAuthenticatorLocalExchangeController = require './controllers/meshblu-authenticator-local-exchange-controller'
StaticSchemasController = require './controllers/static-schemas-controller'
class Router
  constructor: ({@meshbluAuthenticatorLocalExchangeService}) ->
    throw new Error 'Missing meshbluAuthenticatorLocalExchangeService' unless @meshbluAuthenticatorLocalExchangeService?

  route: (app) =>
    meshbluAuthenticatorLocalExchangeController = new MeshbluAuthenticatorLocalExchangeController {@meshbluAuthenticatorLocalExchangeService}
    staticSchemasController = new StaticSchemasController
    app.get '/authenticate', meshbluAuthenticatorLocalExchangeController.signin
    app.post '/authenticate', meshbluAuthenticatorLocalExchangeController.authenticate
    app.get '/public/schemas/:name', staticSchemasController.get
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
