url = require 'url'
Bourse = require 'bourse'

class MeshbluAuthenticatorLocalExchangeService
  constructor:({@formServiceUrl, @authResponseUrl, @exchangeDomainUrl,  @formSchemaUrl, @schemaUrl}) ->
    throw new Error 'Missing required parameter: exchangeDomainUrl' unless @exchangeDomainUrl?

  getAuthorizationUrl: () =>
    {protocol, hostname, port, pathname} = url.parse @formServiceUrl
    query = {
      postUrl: @authResponseUrl
      schemaUrl: @schemaUrl
      formSchemaUrl: @formSchemaUrl
    }
    return url.format {protocol, hostname, port, pathname, query}

  authenticate: ({email, password}, callback) =>
    {protocol, hostname, port}  = url.parse @exchangeDomainUrl
    bourse = new Bourse {protocol, hostname, port, password, username: email}
    bourse.whoami callback

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = MeshbluAuthenticatorLocalExchangeService
