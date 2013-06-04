fermata = require 'fermata'

module.exports.name = 'api'

module.exports.attach = ->
  fermata.registerPlugin 'vlnotify', require('../util/fermata-api-key')
  @api = fermata.vlnotify @config.get('api')

module.exports.init = (done) ->
  done()