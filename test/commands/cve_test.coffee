cve = require '../../app/commands/cve'

describe 'CVE', ->


  it 'should bail out if not recently modified', (done) ->
    nock.cleanAll()
    api.get('/source/cve')
      .reply 200, { source: {
      url: 'http://example.com/cve-modified.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cve-modified.xml')
      .reply 200, '', {'Last-Modified': '2012-12-01T00:00:00.000Z'}

    cve.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.eql {
        message: 'Not modified since last update'
        }
      done()


  it 'should retrieve data if recently modified', (done) ->
    nock.cleanAll()
    api.get('/source/cve')
      .reply 200, { source: {
      url: 'http://example.com/cve-modified.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cve-modified.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/vulnerability')
      .reply 200, { vulnerability: [] }

    server.get('/cve-modified.xml')
      .reply 200, '<nvd/>'

    cve.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should create records', (done) ->
    nock.cleanAll()
    api.get('/source/cve')
      .reply 200, { source: {
      url: 'http://example.com/cve-modified.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cve-modified.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/vulnerability')
      .reply 200, { vulnerability: [] }

    server.get('/cve-modified.xml')
      .reply 200, '''
        <nvd>
          <entry>
            <vuln:cve-id>CVE-2013-9999</vuln:cve-id>
            <vuln:vulnerable-software-list>
              <vuln:product>cpe:/a:vlnotify:vlnotify-fetch:0.0.1</vuln:product>
            </vuln:vulnerable-software-list>
            <vuln:published-datetime>2013-02-01T00:00:00.000Z</vuln:published-datetime>
            <vuln:last-modified-datetime>2013-02-01T00:00:00.000Z</vuln:last-modified-datetime>
            <vuln:cwe id="CWE-20"/>
            <vuln:summary>VLNotify-Fetch doesn't have sufficient test coverage</vuln:summary>
            <vuln:cvss>
              <cvss:base_metrics>
                <cvss:score>5.8</cvss:score>
                <cvss:access-vector>NETWORK</cvss:access-vector>
                <cvss:access-complexity>MEDIUM</cvss:access-complexity>
                <cvss:authentication>NONE</cvss:authentication>
                <cvss:confidentiality-impact>PARTIAL</cvss:confidentiality-impact>
                <cvss:integrity-impact>PARTIAL</cvss:integrity-impact>
                <cvss:availability-impact>NONE</cvss:availability-impact>
                <cvss:source>http://nvd.nist.gov</cvss:source>
                <cvss:generated-on-datetime>
                  2013-02-01T00:00:00.000Z
                </cvss:generated-on-datetime>
              </cvss:base_metrics>
            </vuln:cvss>
            <vuln:references xml:lang="en" reference_type="VENDOR_ADVISORY">
              <vuln:source>SECUNIA</vuln:source>
              <vuln:reference href="http://secunia.com/advisories/51412" xml:lang="en">
                51412
              </vuln:reference>
            </vuln:references>
          </entry>
        </nvd>'''

    api.post('/vulnerability/CVE-2013-9999')
      .reply 201, {}

    cve.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should update records', (done) ->
    nock.cleanAll()
    api.get('/source/cve')
      .reply 200, { source: {
      url: 'http://example.com/cve-modified.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cve-modified.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/vulnerability')
      .reply 200, { vulnerability: [{
      id: 'CVE-2013-9999'
      }]}

    server.get('/cve-modified.xml')
      .reply 200, '''
        <nvd>
          <entry>
            <vuln:cve-id>CVE-2013-9999</vuln:cve-id>
            <vuln:vulnerable-software-list>
              <vuln:product>cpe:/a:vlnotify:vlnotify-fetch:0.0.1</vuln:product>
            </vuln:vulnerable-software-list>
            <vuln:published-datetime>2013-02-01T00:00:00.000Z</vuln:published-datetime>
            <vuln:last-modified-datetime>2013-02-01T00:00:00.000Z</vuln:last-modified-datetime>
            <vuln:cwe id="CWE-20"/>
            <vuln:summary>VLNotify-Fetch doesn't have sufficient test coverage</vuln:summary>
          </entry>
        </nvd>'''

    api.put('/vulnerability/CVE-2013-9999')
      .reply 204, {}

    cve.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should skip invalid records', (done) ->
    nock.cleanAll()
    api.get('/source/cve')
      .reply 200, { source: {
      url: 'http://example.com/cve-modified.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cve-modified.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/vulnerability')
      .reply 200, { vulnerability: [] }

    server.get('/cve-modified.xml')
      .reply 200, '''
        <nvd>
          <entry>
            <vuln:cve-id>CVE-2013-9999</vuln:cve-id>
            <vuln:published-datetime>2013-02-01T00:00:00.000Z</vuln:published-datetime>
            <vuln:last-modified-datetime>2013-02-01T00:00:00.000Z</vuln:last-modified-datetime>
            <vuln:summary>VLNotify-Fetch doesn't have sufficient test coverage</vuln:summary>
          </entry>
        </nvd>'''

    cve.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()


  it 'should skip old records', (done) ->
    nock.cleanAll()
    api.get('/source/cve')
      .reply 200, { source: {
      url: 'http://example.com/cve-modified.xml'
      date_updated: '2013-01-01T00:00:00.000Z'
      }}

    server = nock('http://example.com')
      .head('/cve-modified.xml')
      .reply 200, '', {'Last-Modified': '2013-02-01T00:00:00.000Z'}

    api.get('/vulnerability')
      .reply 200, { vulnerability: [{
      id: 'CVE-2013-9999'
      }]}

    server.get('/cve-modified.xml')
      .reply 200, '''
        <nvd>
          <entry>
            <vuln:cve-id>CVE-2013-9999</vuln:cve-id>
            <vuln:published-datetime>2012-12-01T00:00:00.000Z</vuln:published-datetime>
            <vuln:last-modified-datetime>2012-12-01T00:00:00.000Z</vuln:last-modified-datetime>
            <vuln:summary>VLNotify-Fetch doesn't have sufficient test coverage</vuln:summary>
          </entry>
        </nvd>'''

    cve.fetch (err) ->
      api.done()
      server.done()
      expect(err)
        .to.be.null
      done()