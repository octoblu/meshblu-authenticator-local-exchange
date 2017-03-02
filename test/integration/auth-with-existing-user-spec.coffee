{afterEach, beforeEach, describe} = global
sinon = require 'sinon'

shmock        = require 'shmock'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
fs            = require 'fs'
path          = require 'path'

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
