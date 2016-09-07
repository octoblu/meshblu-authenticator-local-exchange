class MeshbluAuthenticatorLocalExchangeController
  constructor: ({@meshbluAuthenticatorLocalExchangeService}) ->
    throw new Error 'Missing meshbluAuthenticatorLocalExchangeService' unless @meshbluAuthenticatorLocalExchangeService?

  hello: (request, response) =>
    {hasError} = request.query
    @meshbluAuthenticatorLocalExchangeService.doHello {hasError}, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(200)

module.exports = MeshbluAuthenticatorLocalExchangeController
