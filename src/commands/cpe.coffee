app = require '../app'
Fetch = require '../util/fetch'
cpe_uri = require 'cpe-uri'
async = require 'async'

cpe = module.exports

cpe.fetch = () ->
  cpes = new Fetch {
    api: app.api
    http: app.http
    sourceId: 'cpe'
    apiPath: 'cpe'
    xpath: '/cpe-list/cpe-item'

    isValid: (record, recordId) ->
      return !/:-$/.test(recordId)

    recordId: (record) ->
      return cpe_uri.bind(cpe_uri.unbind(record['name']))

    recordLastModified: (record) ->
      return new Date(record['meta$item-metadata']['modification-date'])

    recordTitle: (record) ->
      titleNodes = record['title']
      titleNodes = [titleNodes] if not Array.isArray(titleNodes)
      for titleNode in titleNodes
        if titleNode['xml$lang'] is 'en-US'
          return titleNode['$t']
      return titleNodes[0]['$t']

    toDocument: (record, recordId) ->
      return {
        id: recordId
        title_hint: this.recordTitle(record)
      }
  }
  
  toCreate = []
  cpes.on 'create', (data, done) ->
    toCreate.push(data)
    done()

  toUpdate = []
  cpes.on 'update', (data, done) ->
    toUpdate.push(data)
    done()

  cpes.fetch (err) ->
    return if err

    timerSave = console.log.startTimer()
    api = app.api('cpe')
    async.series [
      (series) ->
        console.log.info "Creating #{toCreate.length} records"
        timerCreate = console.log.startTimer()
        async.eachSeries toCreate, (data, each) ->
          timerEach = console.log.startTimer()
          api([data.id]).post data, (err, result) ->
            if err
              console.log.error "Error creating record #{data.id}: #{JSON.stringify(err)}"
              return each(err)
            timerEach.done "Created record #{data.id}"
            each()
        , (err) ->
          timerCreate.done "Created #{toCreate.length} records" if not err
          series(err)

      (series) ->
        console.log.info "Updating #{toUpdate.length} records"
        timerUpdate = console.log.startTimer()
        async.eachSeries toUpdate, (data, each) ->
          timerEach = console.log.startTimer()
          api([data.id]).put data, (err, result) ->
            if err
              console.log.error "Error updating record #{data.id}: #{JSON.stringify(err)}"
              return each(err)
            timerEach.done "Updated record #{data.id}"
            each()
        , (err) ->
          timerUpdate.done "Updated #{toUpdate.length} records" if not err
          series(err)
    ], (err) ->
      timerSave.done 'Fetch complete'
      

