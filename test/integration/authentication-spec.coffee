shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
_             = require 'lodash'
fs            = require 'fs'
path          = require 'path'

CHALLENGE = _.trim fs.readFileSync path.join(__dirname, '../fixtures/challenge.b64'), encoding: 'utf8'
NEGOTIATE = _.trim fs.readFileSync path.join(__dirname, '../fixtures/negotiate.b64'), encoding: 'utf8'
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
      authHostname: 'citrino.biz'
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
            username: 'foo',
            password: 'bar'
          }

        @negotiate = @exchangeServerMock
          .post '/EWS/Exchange.asmx'
          .set 'Authorization', NEGOTIATE
          .reply 401, '', {'WWW-Authenticate': CHALLENGE}

        @getUser = @exchangeServerMock
          .post '/EWS/Exchange.asmx'
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
              username: 'foo',
              password: 'bar'
            }

          @negotiate = @exchangeServerMock
            .post '/EWS/Exchange.asmx'
            .set 'Authorization', NEGOTIATE
            .reply 401, '', {'WWW-Authenticate': CHALLENGE}

          @getUser = @exchangeServerMock
            .post '/EWS/Exchange.asmx'
            .reply 200

          @meshblu
            .post '/search/devices'
            .send 'authenticator-uuid.id': 'foo'
            .reply 200, []

          @meshblu
            .get '/v2/devices'
            .query 'authenticator-uuid.id': 'foo'
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

      describe 'when the meshblu device already exists', ->
        beforeEach 'request.post', (done) ->
          options =
            uri: '/authenticate'
            baseUrl: "http://localhost:#{@serverPort}"
            json: {
              username: 'foo',
              password: 'bar'
            }

          @negotiate = @exchangeServerMock
            .post '/EWS/Exchange.asmx'
            .set 'Authorization', NEGOTIATE
            .reply 401, '', {'WWW-Authenticate': CHALLENGE}

          @getUser = @exchangeServerMock
            .post '/EWS/Exchange.asmx'
            .reply 200

          @meshblu
            .post '/search/devices'
            .send 'authenticator-uuid.id': 'foo'
            .reply 200, [{
                uuid: 'user-uuid'
                token: 'hashed-user-token'
                owner: "user-uuid"
                'authenticator-uuid': {
                  signature: "DjKlbv3xa1ZFmedeO6eArqY1DMyZKfi5u9fMfVQdr7v/WZUNhiNziSRxQiBnpD2vTkGcpFivGiYF/IqtSNSvXoc4zlcU4IW1Gca6UfVTLM28j4Vpc7i1xDSERJbxzxrL4Wxrbexx/lgNOnpNyJ7Lpohzyxc67ZsfanhYqtDDbe48RolpWzi6MLtaedrYo2HsmJ9V5RWhB0XJdet8PxrXMxB0sC0gQh+jVmY/q1Ax2egzt5n/2d0DJ+Gsb87YhkDAEOta28GH+HZD4X3Vhr8josjg68SARv7f+O5UQICX94ZPt/BcFeoue1zf/s28KG660M/1aKm1PUg47uGUI+DS2g=="
                  id: "foo"
                  secret: "$2a$08$dPm67omlqnUaklw/qbYUUOE82lUTfNjToU4EGJf.h6VLTb9TcsM9W"
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
