cpe = require '../../app/commands/cpe'

describe 'CPE', ->


  it 'should bail out if not recently modified', (done) ->
    nock.cleanAll()
    api.get('/source/cpe')
      .reply 200, { source: {
      url: 'http://example.com/cpe.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cpe.xml')
      .reply 200, '', {'Last-Modified': '2012-12-01T00:00:00.000Z'}

    cpe.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.eql {
        message: 'Not modified since last update'
        }
      done()


  it 'should retrieve data if recently modified', (done) ->
    nock.cleanAll()
    api.get('/source/cpe')
      .reply 200, { source: {
      url: 'http://example.com/cpe.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cpe.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/cpe')
      .reply 200, { cpe: [] }

    server.get('/cpe.xml')
      .reply 200, '<cpe-list/>'

    cpe.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should create records', (done) ->
    nock.cleanAll()
    api.get('/source/cpe')
      .reply 200, { source: {
      url: 'http://example.com/cpe.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cpe.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/cpe')
      .reply 200, { cpe: [] }

    server.get('/cpe.xml')
      .reply 200, '''
        <cpe-list>
          <cpe-item name="cpe:/a:vlnotify:vlnotify-fetch:0.0.1">
            <title xml:lang="en-US">VLNotify-Fetch 0.0.1</title>
            <meta:item-metadata modification-date="2013-02-01T00:00:00.000Z"/>
          </cpe-item>
        </cpe-list>'''

    api.post('/cpe/a:vlnotify:vlnotify-fetch:0.0.1')
      .reply 201, {}

    cpe.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should update records', (done) ->
    nock.cleanAll()
    api.get('/source/cpe')
      .reply 200, { source: {
      url: 'http://example.com/cpe.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cpe.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/cpe')
      .reply 200, { cpe: [{
      id: 'a:vlnotify:vlnotify-fetch:0.0.1'
      }]}

    server.get('/cpe.xml')
      .reply 200, '''
        <cpe-list>
          <cpe-item name="cpe:/a:vlnotify:vlnotify-fetch:0.0.1">
            <title xml:lang="en-US">VLNotify-Fetch 0.0.1</title>
            <meta:item-metadata modification-date="2013-02-01T00:00:00.000Z"/>
          </cpe-item>
        </cpe-list>'''

    api.put('/cpe/a:vlnotify:vlnotify-fetch:0.0.1')
      .reply 204, {}

    cpe.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should skip invalid records', (done) ->
    nock.cleanAll()
    api.get('/source/cpe')
      .reply 200, { source: {
      url: 'http://example.com/cpe.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cpe.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/cpe')
      .reply 200, { cpe: [] }

    server.get('/cpe.xml')
      .reply 200, '''
        <cpe-list>
          <cpe-item name="cpe:/a:vlnotify:vlnotify-fetch:-">
            <title xml:lang="en-US">VLNotify-Fetch</title>
            <meta:item-metadata modification-date="2013-02-01T00:00:00.000Z"/>
          </cpe-item>
        </cpe-list>'''

    cpe.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should skip old records', (done) ->
    nock.cleanAll()
    api.get('/source/cpe')
      .reply 200, { source: {
      url: 'http://example.com/cpe.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cpe.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/cpe')
      .reply 200, { cpe: [{
      id: 'a:vlnotify:vlnotify-fetch:0.0.1'
      }]}

    server.get('/cpe.xml')
      .reply 200, '''
        <cpe-list>
          <cpe-item name="cpe:/a:vlnotify:vlnotify-fetch:0.0.1">
            <title xml:lang="en-US">VLNotify-Fetch 0.0.1</title>
            <meta:item-metadata modification-date="2012-12-01T00:00:00.000Z"/>
          </cpe-item>
        </cpe-list>'''

    cpe.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()