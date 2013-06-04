require('source-map-support').install()

before ->
  global.sinon = require('sinon')
  
  chai = require('chai')
  global.expect = chai.expect
  chai.use require('sinon-chai')
  
  global.async = require('async')
  global.nock = require('nock')
  
  app = require('../app/app')
  global.api = global.nock(app.config.get('api:url'))
