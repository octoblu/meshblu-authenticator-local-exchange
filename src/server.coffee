cors              = require 'cors'
enableDestroy     = require 'server-destroy'
octobluExpress    = require 'express-octoblu'
MeshbluAuth       = require 'express-meshblu-auth'
RedisPooledClient = require 'express-redis-pooled-client'
MeshbluHttp       = require 'meshblu-http'
morgan            = require 'morgan'

debug       = require('debug')('meshblu-authenticator-local-exchange:server')
Router      = require './router'
AuthService = require './services/auth-service'

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
    @redisUri
  }) ->
    throw new Error 'Missing afterAuthRedirectUrl' unless @afterAuthRedirectUrl?
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing redisUri' unless @redisUri?

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
    })

    @redisPooledClient = new RedisPooledClient {
      maxConnections: 5
      minConnections: 1
      namespace: 'meshblu-authenticator-local-exchange'
      redisUri: @redisUri
    }

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging, disableCors: true })
    app.use cors(exposedHeaders: ['Location', 'location'])
    app.use morgan('dev', immediate: true)
    app.use @redisPooledClient.middleware

    router = new Router {@meshbluConfig, @afterAuthRedirectUrl, @authService}
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: (callback) =>
    @server.destroy(callback)

module.exports = Server
