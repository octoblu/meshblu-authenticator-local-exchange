MeshbluAuthenticatorLocalExchangeController = require './controllers/meshblu-authenticator-local-exchange-controller'

class Router
  constructor: ({@meshbluAuthenticatorLocalExchangeService}) ->
    throw new Error 'Missing meshbluAuthenticatorLocalExchangeService' unless @meshbluAuthenticatorLocalExchangeService?

  route: (app) =>
    meshbluAuthenticatorLocalExchangeController = new MeshbluAuthenticatorLocalExchangeController {@meshbluAuthenticatorLocalExchangeService}

    app.get '/hello', meshbluAuthenticatorLocalExchangeController.hello
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
