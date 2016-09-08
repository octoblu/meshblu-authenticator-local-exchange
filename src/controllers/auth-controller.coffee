url = require 'url'

class AuthController
  constructor: ({@authService, @afterAuthRedirectUrl}) ->
    throw new Error 'Missing authService' unless @authService?
    throw new Error 'Missing afterAuthRedirectUrl' unless @afterAuthRedirectUrl?

  signin: (request, response ) =>
    return response.redirect(301, @authService.getAuthorizationUrl())

  authenticate: (request, response) =>
    { email, password } = request.body
    @authService.authenticate {email, password}, (error, user) =>
      return response.sendError error if error?
      return response.sendStatus 401 unless user?
      return response.redirect(201, @_buildRedirectUrl({email, user}))

  _buildRedirectUrl: ({email, user}) =>
    bearerToken = new Buffer("#{user.uuid}:#{user.token}").toString 'base64'

    {protocol, hostname, port, path} = url.parse @afterAuthRedirectUrl

    return url.format {protocol, hostname, port, path, query: {bearerToken}}


module.exports = AuthController
