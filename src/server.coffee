cors           = require 'cors'
enableDestroy  = require 'server-destroy'
octobluExpress = require 'express-octoblu'
MeshbluAuth    = require 'express-meshblu-auth'
MeshbluHttp    = require 'meshblu-http'
Router         = require './router'
AuthService    = require './services/auth-service'
debug          = require('debug')('meshblu-authenticator-local-exchange:server')
serveStatic = require 'serve-static'

class Server
  constructor: ({
    @logFn
    @disableLogging
    @port
    @exchangeDomainUrl
    @formServiceUrl
    @formSchemaUrl
    @schemaUrl
    @afterAuthRedirectUrl
    @activeDirectoryConnectorUuid
    @authResponseUrl
    @meshbluConfig
    redisClient
  }) ->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing afterAuthRedirectUrl' unless @afterAuthRedirectUrl?

    @meshbluHttp = new MeshbluHttp @meshbluConfig
    @meshbluHttp.setPrivateKey @meshbluConfig.privateKey

    @authService = new AuthService({
      @meshbluHttp
      @meshbluConfig
      @exchangeDomainUrl
      @formServiceUrl
      @formSchemaUrl
      @authResponseUrl
      @activeDirectoryConnectorUuid
      @schemaUrl
      redisClient
    })

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging, disableCors: true })
    app.use cors(exposedHeaders: ['Location', 'location'])

    router = new Router {@meshbluConfig, @afterAuthRedirectUrl, @authService}
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: (callback) =>
    @server.destroy(callback)

module.exports = Server
