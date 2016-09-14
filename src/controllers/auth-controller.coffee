url = require 'url'

class AuthController
  constructor: ({@authService, @afterAuthRedirectUrl}) ->
    throw new Error 'Missing authService' unless @authService?
    throw new Error 'Missing afterAuthRedirectUrl' unless @afterAuthRedirectUrl?

  signin: (req, res) =>
    return res.redirect(301, @authService.getAuthorizationUrl())

  authenticate: (req, res) =>
    redisClient = req.redisClient
    { username, password } = req.body

    @authService.authenticate {redisClient, username, password}, (error, user) =>
      return res.sendError error if error?
      return res.sendStatus 401 unless user?
      return res.redirect(201, @_buildRedirectUrl({user}))

  message: (req, res) =>
    redisClient = req.redisClient
    response = req.body

    @authService.storeResponse {redisClient, response}, (error) =>
      return res.sendError error if error?
      return res.sendStatus 204

  _buildRedirectUrl: ({user}) =>
    bearerToken = new Buffer("#{user.uuid}:#{user.token}").toString 'base64'

    {protocol, hostname, port, pathname} = url.parse @afterAuthRedirectUrl

    return url.format {protocol, hostname, port, pathname, query: {bearerToken}}


module.exports = AuthController
