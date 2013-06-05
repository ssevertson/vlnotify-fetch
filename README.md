[![Build Status](https://travis-ci.org/ssevertson/vlnotify-fetch.png?branch=master)](https://travis-ci.org/ssevertson/vlnotify-fetch)
[![Coverage Status](https://coveralls.io/repos/ssevertson/vlnotify-fetch/badge.png?branch=master)](https://coveralls.io/r/ssevertson/vlnotify-fetch?branch=master)

vlnotify-fetch
==============

Command line client and IronWorker implemenation to retrieve NVD's official CPE and recently modified
CVE lists, parse the contents, and send to VLNotify-API for storage and indexing.

Configuration
-------------

`config/config.json` includes a number of placeholder values, including API keys and passwords.
To specify your own values:

1. Edit the file directly (not preferred, as you may inadvertantly commit these back to GitHub)

2. Environment variables: use the variable's JSON path, separated by the '_' character. For example,
  `resourceful_auth_password='your password'`

3. Command-line arguments: use the variable's JSON path, separated by the '.' character. For example,
  `--resourceful.auth.password='your password'`

4. Provide a "payload" JSON file to merge in via command-line arguments. For example, 
  `-payload /path/to/file.json` or `--payload=/path/to/file.json`


Running
-------

Two commands are currently supported:

    node /app/app.js cve fetch

Retrieves CVE updates from URL returned by HTTP GET to `{api.uri}/source/cve`, parses them, and issues
POST/PUTs to `{api.uri}/vulnerability/{id}`.

    node /app/app.js cpe fetch

Retrieves CVE updates from URL returned by HTTP GET `{api.uri}/source/cpe`, parses them, and issues
POST/PUTs to `{api.uri}/cpe/{id}`.
