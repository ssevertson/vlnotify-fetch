require('source-map-support').install()
path = require 'path'
loggly = require 'winston-loggly'
flatiron = require 'flatiron'
dustRenderStrings = require 'dust-render-strings'
require 'date-utils'

app = module.exports = flatiron.app
app.root = if path.basename(__dirname) is 'app'
  path.dirname __dirname
else
  __dirname

# Fix IronWorker's non-standard payload argument
for arg, index in process.argv
  process.argv[index] = '--payload' if arg is '-payload'

app.config
  .argv()
  .env('_')
  .file(path.join app.root, 'config/config.json')

# IronWorker payload support
payload = app.config.get('payload')
app.config.file('payload', payload) if payload

# Support dust.js templates in config strings to reduce redundant values
app.config.stores.literal.store = dustRenderStrings(app.config.get())

# flatiron/broadway currently depend on Winston 0.6.2
# We want 0.7.x for string interpolation
app.use require(path.join app.root, 'app/util/log')

# Replace console.log with winston.info by default; augment with all other Winston methods
console.log = app.log.info
for key, val of app.log
  console.log[key] = val

app.use require(path.join app.root, 'app/init/api')

app.use flatiron.plugins.cli, {
  dir: path.join(__dirname, 'commands'),
  usage: [
    'Retrieve latest CPEs or vulnerabilities and parse for new entries'
  ]
}

# Override command line arguments with config/payload if specified
args = app.config.get('cmd:args')
app.argv['_'] = args.split(' ') if args

app.start()
