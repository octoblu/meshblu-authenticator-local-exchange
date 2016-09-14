_ = require 'lodash'
url = require 'url'
Bourse = require 'bourse'
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
debug = require('debug')('meshblu-authenticator-local-exchange:service')
FAKE_SECRET = 'local-exchange'
uuid = require 'uuid'

class AuthService
  constructor:({
    @activeDirectoryConnectorUuid
    @authResponseUrl
    @exchangeDomainUrl
    @formSchemaUrl
    @formServiceUrl
    @meshbluConfig
    @meshbluHttp
    @schemaUrl
    @redisClient
  }) ->
    throw new Error 'Missing required parameter: exchangeDomainUrl' if _.isEmpty @exchangeDomainUrl
    throw new Error 'Missing required parameter: activeDirectoryConnectorUuid' if _.isEmpty @activeDirectoryConnectorUuid
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


  storeResponse: (response, callback) =>
    responseId = _.get response, 'metadata.to'
    return callback @_createError 422, 'missing required parameter metadata.to' unless responseId?
    @redisClient.lpush responseId, JSON.stringify(response), callback

  _create: ({username, query}, callback) =>
    @_getUserInfo username, (error, userInfo) =>
      return callback error if error?

      @deviceModel.create {
        query: query,
        data: {
          name: userInfo.displayName
          email: userInfo.email
        }
        user_id: username
        secret: FAKE_SECRET
      }, (error, device) =>
        return callback error if error?
        return callback null, device

  _getUserInfo: (username, callback) =>
    message =
      devices: [@activeDirectoryConnectorUuid]
      metadata:
        respondTo: uuid.v1()
      data:
        username: username

    @meshbluHttp.message message, (error) =>
      return callback error if error?
      @redisClient.brpop message.metadata.respondTo, 15, (error, result) =>
        return callback error if error?
        return callback new Error('Timeout') unless result?
        {data} = JSON.parse _.last result
        return callback null, data

  _generateToken: ({device}, callback) =>
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
