url = require 'url'
class MeshbluAuthenticatorLocalExchangeService
  constructor:({@formServiceUrl, @authResponseUrl, @formSchemaUrl, @schemaUrl}) ->

  getAuthorizationUrl: () =>
    {protocol, hostname, port, pathname} = url.parse @formServiceUrl
    query = {
      postUrl: @authResponseUrl
      schemaUrl: @schemaUrl
      formSchemaUrl: @formSchemaUrl
    }
    return url.format {protocol, hostname, port, pathname, query}

  # doHello: ({hasError}, callback) =>
  #   return callback @_createError(500, 'Not enough dancing!') if hasError?
  #   callback()

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = MeshbluAuthenticatorLocalExchangeService
