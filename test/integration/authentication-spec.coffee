shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
_             = require 'lodash'
fs            = require 'fs'
path          = require 'path'

CHALLENGE = _.trim fs.readFileSync path.join(__dirname, '../fixtures/challenge.b64'), encoding: 'utf8'
NEGOTIATE = _.trim fs.readFileSync path.join(__dirname, '../fixtures/negotiate.b64'), encoding: 'utf8'
USER_SETTINGS_RESPONSE = fs.readFileSync path.join(__dirname, '../fixtures/userSettingsResponse.xml'), encoding: 'utf8'

describe 'Local Exchange Authenticator', ->
  beforeEach (done) ->
    @meshblu = shmock()
    @exchangeServerMock = shmock()
    enableDestroy @meshblu
    enableDestroy @exchangeServerMock

    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      exchangeDomainUrl: "http://localhost:#{@exchangeServerMock.address().port}"
      formServiceUrl: 'https://form-service.octoblu.com'
      formSchemaUrl: 'https://meshblulocalexchange.localtunnel.me/public/schemas/api-authentication-form.cson'
      schemaUrl: 'https://meshblulocalexchange.localtunnel.me/public/schemas/api-authentication-form.cson'
      logFn: @logFn
      meshbluConfig:
        hostname: 'localhost'
        protocol: 'http'
        resolveSrv: false
        port: 0xd00d

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach 'destroy server', (done) ->
    @server.destroy(done)

  afterEach 'destroy exchange', (done) ->
    @exchangeServerMock.destroy(done)

  afterEach 'destroy meshblu', (done) ->
    @meshblu.destroy(done)

  describe 'on POST /authenticate', ->
    describe 'when the user authentication is invalid', ->
      beforeEach (done) ->
        options =
          uri: '/authenticate'
          baseUrl: "http://localhost:#{@serverPort}"
          json: {
            email: 'foo@biz.biz',
            password: 'bar'
          }

        @negotiate = @exchangeServerMock
          .post '/autodiscover/autodiscover.svc'
          .set 'Authorization', NEGOTIATE
          .reply 401, '', {'WWW-Authenticate': CHALLENGE}

        @getUser = @exchangeServerMock
          .post '/autodiscover/autodiscover.svc'
          .reply 401

        request.post options, (error, @response, @body) =>
          done error

      it.only 'Should return a 401', ->
        expect(@response.statusCode).to.equal 401, JSON.stringify(@body)

    describe 'when the user authentication is invalid', ->
      beforeEach (done) ->
        options =
          uri: '/authenticate'
          baseUrl: "http://localhost:#{@serverPort}"
          json: {
            email: 'foo@biz.biz',
            password: 'bar'
          }

        @negotiate = @exchangeServerMock
          .post '/autodiscover/autodiscover.svc'
          .set 'Authorization', NEGOTIATE
          .reply 401, '', {'WWW-Authenticate': CHALLENGE}

        @getUser = @exchangeServerMock
          .post '/autodiscover/autodiscover.svc'
          .reply 200, USER_SETTINGS_RESPONSE

        request.post options, (error, @response, @body) =>
          done error

      it 'Should return a 201', ->
        expect(@response.statusCode).to.equal 201
