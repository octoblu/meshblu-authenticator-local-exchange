_ = require 'lodash'

class HealthcheckController
  constructor: ({@healthcheckService}) ->
    throw new Error 'healthcheckService is required' unless @healthcheckService?
    throw new Error 'healthcheckService.healthcheck must be a function' unless _.isFunction @healthcheckService.healthcheck

  get: (req, res) =>
    redisClient = req.redisClient

    @healthcheckService.healthcheck redisClient, (error, response) =>
      return res.sendError error if error?
      return res.status(500).send(response) unless response.healthy
      return res.send response

module.exports = HealthcheckController
