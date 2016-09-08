class MeshbluAuthenticatorLocalExchangeController
  constructor: ({@meshbluAuthenticatorLocalExchangeService}) ->
    throw new Error 'Missing meshbluAuthenticatorLocalExchangeService' unless @meshbluAuthenticatorLocalExchangeService?

  signin: (request, response ) =>
    return response.redirect(301, @meshbluAuthenticatorLocalExchangeService.getAuthorizationUrl())


  authenticate: (request, response) =>
    return response.send(200, 'Ok')

module.exports = MeshbluAuthenticatorLocalExchangeController
