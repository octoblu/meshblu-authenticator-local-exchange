shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

xdescribe 'Local Exchange Authenticator', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu

    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      exchangeDomainUrl: 'https://mail.citrite.net'
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

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  # describe 'on GET /signin', ->
  #   beforeEach (done) ->
  #     options =
  #       uri: '/authenticate'
  #       baseUrl: "http://localhost:#{@serverPort}"
  #       json: true
  #
  #     request.get options, (error, @response, @body) =>
  #       done error
  #
  #   it 'should return a 201', ->
  #     expect(@response.statusCode).to.equal 201
  #
  #   it 'should auth the request with meshblu', ->
  #     @authDevice.done()
  #
  # describe 'when the service yields an error', ->
  #   beforeEach (done) ->
  #     userAuth = new Buffer('some-uuid:some-token').toString 'base64'
  #
  #     @authDevice = @meshblu
  #       .post '/authenticate'
  #       .set 'Authorization', "Basic #{userAuth}"
  #       .reply 204
  #
  #     options =
  #       uri: '/hello'
  #       baseUrl: "http://localhost:#{@serverPort}"
  #       auth:
  #         username: 'some-uuid'
  #         password: 'some-token'
  #       qs:
  #         hasError: true
  #       json: true
  #
  #     request.get options, (error, @response, @body) =>
  #       done error
  #
  #   it 'should log the error', ->
  #     expect(@logFn).to.have.been.called
  #
  #   it 'should auth and response with 500', ->
  #     expect(@response.statusCode).to.equal 500
  #
  #   it 'should auth the request with meshblu', ->
  #     @authDevice.done()
