

import options, asyncdispatch, times, strutils, os, tables, parseutils

import httpbeast, limdb, libsha/sha256

let db = initDatabase("nimshortdb", (url: string))
var hash{.threadvar.}: string
var startup = proc () =
  hash = getEnv("NIMSHORT_HASH")
  if hash == "":
    stderr.write(""" Please create a token, place it into NIMSHORT_TOKEN,
and run the program again to get a hash. Place the hash into NIMSHORT_HASH.
To add URL, use PUT with 'Auth: Bearer MyToken' header.""")
    quit(2)

proc auth(req: Request): bool =
  let headers = req.headers.get
  if "auth" notin headers.table[]:
    req.send(Http401, "'Auth: Bearer MyToken' header required")
  else:
    let auth = headers["auth"]
    if auth.startsWith("Bearer "):
      if sha256hexdigest(auth[7..<auth.len]) == hash:
        result = true
      else:
        req.send(Http403, "Invalid auth token")
    else:
        req.send(Http400, "Auth header needs to start with 'Bearer '")

proc onRequest(req: Request): Future[void] =
  let timestamp = now()
  let httpMethod = req.httpMethod.get
  let path = req.path.get
  echo "$1 $2 $3" % [$timestamp, $httpMethod, $path]
  case httpMethod:
  of HttpHead:
    if path notin db.url:
      req.send(Http404, "Not found")
    else:
      req.send(Http200, "")
  of HttpGet:
    if path notin db.url:
      req.send(Http404, "Not found")
    else:
      req.send(Http301, "", "Location: $1" % db.url[path])
  of HttpPut:
    if req.auth:
      let body = req.body.get
      db.url[path] = body
      req.send(Http201, "Shortened $1 to $2" % [body, path])
  of HttpDelete:
    if req.auth:
      var body: string
      if db.url.pop(path, body):
        req.send(Http201, "$2 deleted from path $1" % [body, path])
      else:
        req.send(Http404, "$1 not found" % path)
  else:
    req.send(Http400, "PUT /myShort with URL as body")

proc hashToken() =
  let token = getEnv("NIMSHORT_TOKEN")
  if token != "":
    stderr.write("$1\n" % sha256hexdigest(token))
    quit(3)

proc port():Port =
  let portEnv = getEnv("NIMSHORT_PORT")
  if portEnv == "":
    Port(7071)
  else:
    Port(parseInt(portEnv))

hashToken()

httpbeast.run(onRequest, initSettings(startup = startup, port = port()))

