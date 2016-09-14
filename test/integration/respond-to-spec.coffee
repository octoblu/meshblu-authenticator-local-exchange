{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'
sinon = require 'sinon'

_             = require 'lodash'
path          = require 'path'
fs            = require 'fs'

uuid          = require 'uuid'
fakeredis     = require 'fakeredis'

redis         = require 'redis'
request       = require 'request'

Server        = require '../../src/server'

MESHBLU_PRIVATE_KEY = fs.readFileSync path.join(__dirname, '../fixtures/meshblu-private-key.b64'), encoding: 'utf8'

describe 'Local Exchange Authenticator', ->
  beforeEach (done) ->
    clientId      = uuid.v1()
    @redisClient  = fakeredis.createClient(clientId)
    redisClient   = fakeredis.createClient(clientId)

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
      redisClient: redisClient
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

  describe 'on POST /message', ->
    describe 'When given a response message', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            metadata:
              respond:
                to: 'some-random-uuid'
            data:
              name: 'Dekard Cain'
              email: 'tyrael@creepy-church.com'

        request.post options, (error) =>
          @redisClient.brpop 'some-random-uuid', 1000, (error, result) =>
            @response = JSON.parse _.last result
            done()

      it 'Should add the response to redis', ->
        expect(@response).to.deep.equal(
          metadata:
            respond:
              to: 'some-random-uuid'
          data:
            name: 'Dekard Cain'
            email: 'tyrael@creepy-church.com'
        )

    describe 'When given a response message without a respond.to', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            data:
              name: 'Dekard Cain'
              email: 'tyrael@creepy-church.com'

        request.post options, (error, @response) => done()
      it 'Should respond with an error indicating the message is invalid', ->
        expect(@response.statusCode).to.equal 422