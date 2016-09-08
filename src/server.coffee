enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
MeshbluAuth        = require 'express-meshblu-auth'
Router             = require './router'
MeshbluAuthenticatorLocalExchangeService = require './services/meshblu-authenticator-local-exchange-service'
debug              = require('debug')('meshblu-authenticator-local-exchange:server')
serveStatic = require 'serve-static'

class Server
  constructor: ({
    @logFn,
    @disableLogging,
    @port,
    @exchangeDomainUrl,
    @formServiceUrl,
    @formSchemaUrl,
    @schemaUrl,
    @authResponseUrl,
    @meshbluConfig
  })->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuthenticatorLocalExchangeService =
      new MeshbluAuthenticatorLocalExchangeService({
        @exchangeDomainUrl,
        @formServiceUrl,
        @formSchemaUrl,
        @authResponseUrl,
        @schemaUrl
      })
    router = new Router {@meshbluConfig, meshbluAuthenticatorLocalExchangeService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: (callback) =>
    @server.destroy(callback) 

module.exports = Server
