module.exports = (transport, apiConfig) ->
  @base = apiConfig.url
  transport = transport \
  .using('statusCheck') \
  .using('autoConvert', 'application/json')

  return (req, callback) ->
    req.headers['x-api-key'] = apiConfig.key
    transport(req, callback)
