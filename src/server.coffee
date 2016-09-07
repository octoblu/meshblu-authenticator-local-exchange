enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
MeshbluAuth        = require 'express-meshblu-auth'
Router             = require './router'
MeshbluAuthenticatorLocalExchangeService = require './services/meshblu-authenticator-local-exchange-service'
debug              = require('debug')('meshblu-authenticator-local-exchange:server')

class Server
  constructor: ({@logFn, @disableLogging, @port, @meshbluConfig})->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()
    app.use meshbluAuth.gateway()

    meshbluAuthenticatorLocalExchangeService = new MeshbluAuthenticatorLocalExchangeService
    router = new Router {@meshbluConfig, meshbluAuthenticatorLocalExchangeService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
