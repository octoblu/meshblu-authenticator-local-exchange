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
    describe 'when the user authentication is valid', ->
      describe 'when the meshblu device already exists', ->
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
            .post '/search/devices'
            .send 'authenticator-uuid.id': 'ada48c41-66c9-407b-bf2a-a7880e611435'
            .reply 200, [{
                uuid: 'user-uuid'
                token: 'hashed-user-token'
                owner: "user-uuid"
                'authenticator-uuid': {
                  signature: "kNEKAGh0EFS92LnWa8LxkjPCi4t+wXiu6+e3eO2k6dWb/03AzHhtIxGmYyvSW/xihq2tr5opF22UFVRk8viZMyfCS1BcUe/TuA85au9jOauPiDKZ1IysiUdNtfEVWnhYuneJfLKMsFX5Jb9wlxqBGfJZagZP9Simvy8mDxFf82qxit2D/tK6GbhSd3WMHIyV07hpbODh5PZB0mnLCZlGS61ZsXqarTcE++dTHjbXetHBfY9QsKtARf6uDDnq3EjNtUdRjDDMw1u7gzDT2Dx2felJfSsJ8+4ocYP+HKidear9WNaGrjSlCAd7rZygX+OBFoqAuQG9lL27qPs6efSmzg=="
                  id: "ada48c41-66c9-407b-bf2a-a7880e611435"
                  secret: "$2a$08$zRhVwpQz0T253Rvq4dXqaeS9k234lH./mx8XBpgnERjo3c2/aOEty"
                }
              }]

          @register = @meshblu
            .post '/devices'
            .reply 501

          @meshblu
            .post '/devices/user-uuid/tokens'
            .reply 201, {uuid: 'user-uuid', token: 'user-token-2'}

          request.post options, (error, @response, @body) =>
            done error

        it 'Should return a 201', ->
          expect(@response.statusCode).to.equal 201

        it 'Should not register a new device', ->
          expect(@register.isDone).to.be.false

        it 'Should return a location header with a meshblu bearer token', ->
          bearerToken = encodeURIComponent new Buffer('user-uuid:user-token-2').toString('base64')
          expect(@response.headers.location).to.deep.equal "http://zombo.com?bearerToken=#{bearerToken}"
