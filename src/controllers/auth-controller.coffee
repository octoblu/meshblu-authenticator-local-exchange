url = require 'url'

class AuthController
  constructor: ({@authService, @afterAuthRedirectUrl}) ->
    throw new Error 'Missing authService' unless @authService?
    throw new Error 'Missing afterAuthRedirectUrl' unless @afterAuthRedirectUrl?

  signin: (request, response ) =>
    return response.redirect(301, @authService.getAuthorizationUrl())

  authenticate: (request, response) =>
    { username, password } = request.body
    @authService.authenticate {username, password}, (error, user) =>
      return response.sendError error if error?
      return response.sendStatus 401 unless user?
      return response.redirect(201, @_buildRedirectUrl({user}))


  message: (request, response) =>
    @authService.storeResponse request.body, (error) =>
      return response.sendError error if error?
      return response.sendStatus 204

  _buildRedirectUrl: ({user}) =>
    bearerToken = new Buffer("#{user.uuid}:#{user.token}").toString 'base64'

    {protocol, hostname, port, pathname} = url.parse @afterAuthRedirectUrl

    return url.format {protocol, hostname, port, pathname, query: {bearerToken}}


module.exports = AuthController
