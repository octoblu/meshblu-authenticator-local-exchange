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
MESHBLU_PRIVATE_KEY = fs.readFileSync path.join(__dirname, '../fixtures/meshblu-private-key.b64'), encoding: 'utf8'

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
      afterAuthRedirectUrl: 'http://zombo.com'
      logFn: @logFn
      meshbluConfig:
        hostname: 'localhost'
        protocol: 'http'
        resolveSrv: false
        port: @meshblu.address().port
        uuid: 'authenticator-uuid'
        token: 'authenticator-token'
        privateKey: MESHBLU_PRIVATE_KEY

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

      it 'Should return a 401', ->
        expect(@response.statusCode).to.equal 401, JSON.stringify(@body)

    describe 'when the user authentication is valid', ->
      describe 'when the meshblu device does not yet exist', ->
        beforeEach 'request.post', (done) ->
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

          @meshblu
            .get '/v2/devices'
            .query 'authenticator-uuid.id': 'ada48c41-66c9-407b-bf2a-a7880e611435'
            .reply 200, []

          @meshblu
            .post '/devices'
            .reply 201, {uuid: 'user-uuid', token: 'user-token'}

          @meshblu
            .patch '/v2/devices/user-uuid'
            .reply 204

          request.post options, (error, @response, @body) =>
            done error

        it 'Should return a 201', ->
          expect(@response.statusCode).to.equal 201

        it 'Should return a location header with a meshblu bearer token', ->
          bearerToken = encodeURIComponent new Buffer('user-uuid:user-token').toString('base64')
          expect(@response.headers.location).to.deep.equal "http://zombo.com?bearerToken=#{bearerToken}"
