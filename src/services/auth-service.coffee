url = require 'url'
Bourse = require 'bourse'
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
debug = require('debug')('meshblu-authenticator-local-exchange:service')

FAKE_SECRET = 'local-exchange'

class AuthService
  constructor:({
    @meshbluHttp,
    @meshbluConfig,
    @formServiceUrl,
    @authResponseUrl,
    @exchangeDomainUrl,
    @formSchemaUrl,
    @schemaUrl,
  }) ->
    throw new Error 'Missing required parameter: exchangeDomainUrl' unless @exchangeDomainUrl?
    @authenticatorUuid = @meshbluConfig.uuid
    authenticatorName = @meshbluConfig.name
    @deviceModel = new DeviceAuthenticator {@authenticatorUuid, authenticatorName, @meshbluHttp}

  getAuthorizationUrl: () =>
    {protocol, hostname, port, pathname} = url.parse @formServiceUrl
    query = {
      postUrl: @authResponseUrl
      schemaUrl: @schemaUrl
      formSchemaUrl: @formSchemaUrl
    }
    return url.format {protocol, hostname, port, pathname, query}

  authenticate: ({username, password}, callback) =>
    {protocol, hostname, port}  = url.parse @exchangeDomainUrl
    bourse = new Bourse {protocol, hostname, port, password, username: username}
    bourse.authenticate (error, authenticated) =>
      return callback error if error?
      return callback @_createError 401, 'Unauthorized' unless authenticated

      query = @_getQuery { id: username }
      @deviceModel.findVerified {query, password: FAKE_SECRET}, (error, device) =>
        return callback error if error?
        return @_create {username, query}, callback unless device?
        return @_generateToken {query, device}, callback

  _create: ({username, query}, callback) =>
    @deviceModel.create {
      query: query,
      user_id: username
      secret: FAKE_SECRET
    }, (error, device) =>
      return callback error if error?
      return callback null, device

  _generateToken: ({query, device}, callback) =>
    @meshbluHttp.generateAndStoreToken device.uuid, (error, credentials) =>
      return callback error if error?
      callback null, credentials

  _getQuery: ({id}) =>
    query = {}
    query["#{@authenticatorUuid}.id"] = id
    return query

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = AuthService
