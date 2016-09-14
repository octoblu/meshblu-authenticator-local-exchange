{beforeEach, describe, it} = global
{expect} = require 'chai'

fs            = require 'fs'
IORedis       = require 'ioredis'
_             = require 'lodash'
path          = require 'path'
RedisNS       = require '@octoblu/redis-ns'
request       = require 'request'

Server        = require '../../src/server'

MESHBLU_PRIVATE_KEY = fs.readFileSync path.join(__dirname, '../fixtures/meshblu-private-key.b64'), encoding: 'utf8'

describe 'Local Exchange Authenticator', ->
  beforeEach (done) ->
    @redisClient = new RedisNS 'meshblu-authenticator-local-exchange', new IORedis('redis://localhost:6379', dropBufferSupport: true)

    serverOptions =
      port: undefined,
      disableLogging: true
      exchangeDomainUrl: "http://localhost:66666"
      activeDirectoryConnectorUuid: '5eac0a575'
      formServiceUrl: 'https://form-service.octoblu.com'
      formSchemaUrl: 'https://meshblulocalexchange.localtunnel.me/public/schemas/api-authentication-form.cson'
      schemaUrl: 'https://meshblulocalexchange.localtunnel.me/public/schemas/api-authentication-form.cson'
      afterAuthRedirectUrl: 'http://zombo.com'
      authHostname: 'citrino.biz'
      logFn: @logFn
      redisUri: 'redis://localhost:6379'
      uuid: @uuid
      meshbluConfig:
        hostname: 'localhost'
        protocol: 'http'
        resolveSrv: false
        port: 5
        uuid: 'authenticator-uuid'
        token: 'authenticator-token'
        privateKey: MESHBLU_PRIVATE_KEY

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  describe 'on POST /messages', ->
    describe 'When given a response message', ->
      beforeEach (done) ->
        options =
          uri: '/messages'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            metadata:
              to: 'some-random-uuid'
            data:
              name: 'Dekard Cain'
              email: 'tyrael@creepy-church.com'

        request.post options, (error) =>
          return done error if error?

          @redisClient.brpop 'some-random-uuid', 1000, (error, result) =>
            @response = JSON.parse _.last result
            done()

      it 'Should add the response to redis', ->
        expect(@response).to.deep.equal(
          metadata:
            to: 'some-random-uuid'
          data:
            name: 'Dekard Cain'
            email: 'tyrael@creepy-church.com'
        )

    describe 'When given a response message without a to', ->
      beforeEach (done) ->
        options =
          uri: '/messages'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            data:
              name: 'Dekard Cain'
              email: 'tyrael@creepy-church.com'

        request.post options, (error, @response) => done()
      it 'Should respond with an error indicating the message is invalid', ->
        expect(@response.statusCode).to.equal 422
