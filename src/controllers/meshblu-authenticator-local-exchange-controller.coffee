class MeshbluAuthenticatorLocalExchangeController
  constructor: ({@meshbluAuthenticatorLocalExchangeService}) ->
    throw new Error 'Missing meshbluAuthenticatorLocalExchangeService' unless @meshbluAuthenticatorLocalExchangeService?

  signin: (request, response ) =>
    return response.redirect(301, @meshbluAuthenticatorLocalExchangeService.getAuthorizationUrl())

  authenticate: (request, response) =>
    { email, password } = request.body
    @meshbluAuthenticatorLocalExchangeService.authenticate {email, password}, (error, user) ->
      return response.sendError error if error?
      return response.send(user).status(201) if user?
      return response.sendStatus(401)


module.exports = MeshbluAuthenticatorLocalExchangeController
