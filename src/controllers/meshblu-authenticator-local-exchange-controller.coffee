class MeshbluAuthenticatorLocalExchangeController
  constructor: ({@meshbluAuthenticatorLocalExchangeService}) ->
    throw new Error 'Missing meshbluAuthenticatorLocalExchangeService' unless @meshbluAuthenticatorLocalExchangeService?

  signin: (request, response ) =>
    return response.redirect(301, @meshbluAuthenticatorLocalExchangeService.getAuthorizationUrl())


  authenticate: (request, response) =>
    {username, password } = request.body
    response.send({'login': 'success'}).status(201)



module.exports = MeshbluAuthenticatorLocalExchangeController
