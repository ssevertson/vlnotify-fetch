iron_mq = require 'iron_mq'
app = require '../app'
Fetch = require '../util/fetch'

cve = module.exports

cve.fetch = (callback) ->
  count = 10
  cves = new Fetch {
    api: app.api
    http: app.http
    sourceId: 'cve'
    apiPath: 'vulnerability'
    xpath: '/nvd/entry'

    isValid: (record) ->
      count--
      return record['vuln$vulnerable-software-list']?['vuln$product'] && count > 0

    recordId: (record) ->
      return record['vuln$cve-id']?['$t']

    recordLastModified: (record) ->
      return new Date(record['vuln$last-modified-datetime']?['$t'])

    toDocument: (record) ->
      doc = {
        id: this.recordId(record)
        summary: record['vuln$summary']['$t']
        cpe: []
        date_created: new Date(record['vuln$published-datetime']?['$t']).toISOString()
        date_updated: this.recordLastModified(record).toISOString()
        cwe: record['vuln$cwe']?['id']
        references: []
      }
      # TODO: Add  references if available
      cpes = record['vuln$vulnerable-software-list']?['vuln$product']
      cpes = [cpes] if not Array.isArray(cpes)
      for cpe in cpes
        doc.cpe.push cpe['$t']

      cvss = record['vuln$cvss']?['cvss$base_metrics']
      if cvss
        doc.cvss = {
          score: parseFloat(cvss['cvss$score']?['$t'])
          access_vector: cvss['cvss$access-vector']?['$t']?.toLowerCase()
          access_complexity: cvss['cvss$access-complexity']?['$t']?.toLowerCase()
          authentication: cvss['cvss$authentication']?['$t']?.toLowerCase()
          confidentiality_impact: cvss['cvss$confidentiality-impact']?['$t']?.toLowerCase()
          integrity_impact: cvss['cvss$integrity-impact']?['$t']?.toLowerCase()?.toLowerCase()
          availability_impact: cvss['cvss$availability-impact']?['$t']?.toLowerCase()
          date_created: new Date(cvss['cvss$generated-on-datetime']?['$t']).toISOString()
          source: cvss['cvss$source']?['$t']
        }

      references = record['vuln$references']
      if references
        references = [references] if not Array.isArray(references)
        for reference in references
          doc.references.push {
            type: reference['reference_type'].toLowerCase()
            lang: reference['xml$lang']
            url: reference['vuln$reference']['href']
            source: reference['vuln$source']['$t']
            title: reference['vuln$reference']['$t']
          }

      return doc
  }

  api = app.api('vulnerability')
  cves.on 'create', (data, done) ->
    timer = console.log.startTimer()
    api([data.id]).post data, (err, result) ->
      console.log.error "Error creating record #{data.id}: #{JSON.stringify(err)}" if err
      timer.done "Created record #{data.id}" if not err
      return done(err)

  cves.on 'update', (data, done) ->
    timer = console.log.startTimer()
    api([data.id]).put data, (err, result) ->
      console.log.error "Error updating record #{data.id}: #{JSON.stringify(err)}" if err
      timer.done "Updated record #{data.id}" if not err
      done(err)

  cves.fetch (err) ->
    console.log.error "Error fetching CVEs: #{JSON.stringify(err)}" if err
    callback(err) if callback
