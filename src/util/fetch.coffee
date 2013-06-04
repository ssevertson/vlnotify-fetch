util = require 'utile'
async = require 'async'
{EventEmitter} = require 'events'
url = require 'url'
XMLSplitter = require 'xml-splitter'
app = require '../app'

fetch = module.exports = class Fetch extends EventEmitter
  constructor: (options) ->
    util.mixin(@, options)

  fetch: (callback) ->
    self = @
    async.waterfall [

      (waterfall) ->

        console.log.info "Retrieving source for #{self.sourceId}"
        timer = console.log.startTimer()

        self.api('source')(self.sourceId).get (err, result) ->
          timer.done "Retrieved source for #{self.sourceId}"

          return waterfall(err) if err

          parsed = url.parse(result.source.url)
          source = {
            url: parsed
            http: require(parsed.protocol.slice(0, -1))
            updated: new Date(result.source.date_updated)
          }
          waterfall(null, source)

      (source, waterfall) ->

        console.log.info "Retrieving head for #{self.sourceId}"
        timer = console.log.startTimer()

        options = util.mixin {method: 'HEAD'}, source.url
        req = source.http.request options, (res) ->
          timer.done "Retrieved head for #{self.sourceId}"

          modified = new Date(res.headers['last-modified'])

          if modified.isAfter source.updated
            waterfall(null, source)
          else
            waterfall {message: 'Not modified since last update'}

        req.end()

      (source, waterfall) ->

        timer = console.log.startTimer()
        console.log.info "Retrieving existing records for #{self.sourceId}"
        self.api(self.apiPath).get (err, result) ->
          return waterfall(err) if err

          container = result[Object.keys(result)[0]]
          timer.done "Retrieved #{container.length} existing records"

          existing = {}
          for record in container
            existing[record.id] = true

          waterfall(null, source, existing)

      (source, existing, waterfall) ->

        console.log.info "Retrieving body for #{self.sourceId}"
        timer = console.log.startTimer()

        options = util.mixin {method: 'GET'}, source.url
        req = source.http.request options, (res) ->
          timer.done "Retrieved body for #{self.sourceId}"

          splitter = new XMLSplitter self.xpath

          pending = {
            data: {}
            total: 0
            skipped: 0
            processed: 0
            done: (total) ->
              @total = total
              @complete = true
              if @processed + @skipped is @total
                waterfall(null, @total)
            add: (recordId) ->
              @data[recordId] = true
            remove: (recordId) ->
              delete @data[recordId]
              @processed++
              if @complete and Object.keys(@data).length is 0
                waterfall(null, @total)
          }
          splitter.on 'data', (record) ->
            recordId = self.recordId(record)
            if self.isValid(record, recordId)
              event = if not existing[recordId]
                'create'
              else if self.recordLastModified(record, recordId).isAfter source.updated
                'update'
              else
                null
              if event
                doc = self.toDocument(record, recordId)
                pending.add(recordId)
                self.emit event, doc, () ->
                  pending.remove(recordId)
            else
              pending.skipped++

          console.log.info "Parsing body for #{self.sourceId}"
          timer = console.log.startTimer()
          splitter.on 'end', (total) ->
            timer.done "Parsed body for #{self.sourceId}"
            pending.done(total)

          splitter.parseStream res

        req.end()

#      (total, waterfall) ->
#        console.log.info "Updating date_updated on source #{self.sourceId}"
#        self.api('source')(self.sourceId).put {
#          date_updated: new Date().toISOString()
#        }, (err, result) ->
#          console.log.error \
#            "Error updating date_updated on source #{self.sourceId}: #{JSON.stringify(err)}" if err
#          waterfall(err, total)

    ], (err, total) ->

      console.log.error "Error for source #{self.sourceId}: #{JSON.stringify(err)}" if err
      console.log.info "Processed #{total} records" if total

      callback(err, total)

  recordId: (record) ->
    # Default record ID retrieval
    return undefined

  recordLastModified: (record, recordId) ->
    # Default last modified implementation
    return new Date()

  toDocument: (record, recordId) ->
    # Default document conversion method
    return record

  isValid: (record, recordId) ->
    # Default record validity check
    return true