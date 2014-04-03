# Express middleware for our Admin app
#
r           = require 'rethinkdb'
{db}        = require '../config'
dbConfig    = db

# Add the rethink connection objects to the request
#
exports.rethink = ->
    (req, res, next) ->
        r.connect host: dbConfig.address, port: dbConfig.port,
            (err, conn) ->
                return next err if err?
                conn.use dbConfig.adminDb.name
                req.rethink =
                    conn: conn
                    r: r
                next()

# Determine which client is talking to us, and send the
# appropriate response
#
sendFail = (req, res, redirectUrl) ->
    if /json/.test req.headers['Accept'] or /json/.test req.headers['accept']
        res.status 403
        res.send status: 'failed'
    else if redirectUrl?
        res.redirect redirectUrl
    else
        res.send 404

# Ensure a user with the needed permissions is accessing the route
#
exports.requireUser = (permission, redirectUrl) ->
    ANY_USER = '*'
    (req, res, next) ->
        unless req.session?.user and \
            (req.session.user.permission is permission or permission is ANY_USER)
                return sendFail req, res, redirectUrl
        next()
