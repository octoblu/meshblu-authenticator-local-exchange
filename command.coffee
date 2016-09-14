_             = require 'lodash'
MeshbluConfig = require 'meshblu-config'
Server        = require './src/server'
IORedis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'

class Command
  getOptions: =>
    @panic new Error('Missing required environment variable: AUTH_RESPONSE_URL') if _.isEmpty process.env.AUTH_RESPONSE_URL
    @panic new Error('Missing required environment variable: AFTER_AUTH_REDIRECT_URL') if _.isEmpty process.env.AFTER_AUTH_REDIRECT_URL
    @panic new Error('Missing required environment variable: EXCHANGE_DOMAIN_URL') if _.isEmpty process.env.EXCHANGE_DOMAIN_URL
    @panic new Error('Missing required environment variable: FORM_SERVICE_URL') if _.isEmpty process.env.FORM_SERVICE_URL
    @panic new Error('Missing required environment variable: FORM_SERVICE_URL') if _.isEmpty process.env.FORM_SERVICE_URL
    @panic new Error('Missing required environment variable: MESSAGE_SCHEMA_URL') if _.isEmpty process.env.MESSAGE_SCHEMA_URL
    @panic new Error('Missing required environment variable: AUTH_HOSTNAME') if _.isEmpty process.env.AUTH_HOSTNAME
    @panic new Error('Missing required environment variable: ACTIVE_DIRECTORY_CONNECTOR_UUID') if _.isEmpty process.env.ACTIVE_DIRECTORY_CONNECTOR_UUID
    @panic new Error('Missing required environment variable: REDIS_URI') if _.isEmpty process.env.REDIS_URI

    return {
      meshbluConfig:                new MeshbluConfig().toJSON()
      port:                         process.env.PORT || 80
      afterAuthRedirectUrl:         process.env.AFTER_AUTH_REDIRECT_URL
      exchangeDomainUrl:            process.env.EXCHANGE_DOMAIN_URL
      formServiceUrl:               process.env.FORM_SERVICE_URL
      formSchemaUrl:                process.env.FORM_SCHEMA_URL
      schemaUrl:                    process.env.MESSAGE_SCHEMA_URL
      authResponseUrl:              process.env.AUTH_RESPONSE_URL
      disableLogging:               process.env.DISABLE_LOGGING == "true"
      authHostname:                 process.env.AUTH_HOSTNAME
      activeDirectoryConnectorUuid: process.env.ACTIVE_DIRECTORY_CONNECTOR_UUID
    }

  panic: (error) =>
    console.error error.stack
    process.abort() # process.exit(1) wouldn't die immediately?

  run: =>
    redisClient = new IORedis process.env.REDIS_URI
    redisClient.on 'error', @panic
    redisClient.once 'ready', =>

      options = _.defaults({
        redisClient: new RedisNS 'meshblu-authenticator-local-exchange', redisClient
      }, @getOptions())

      server = new Server options
      server.run (error) =>
        return @panic error if error?

        {address,port} = server.address()
        console.log "MeshbluAuthenticatorLocalExchangeService listening on port: #{port}"

      process.on 'SIGTERM', =>
        console.log 'SIGTERM caught, exiting'
        return process.exit 0 unless server?.stop?
        server.stop =>
          process.exit 0

command = new Command()
command.run()
