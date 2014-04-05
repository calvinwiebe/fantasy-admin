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

# Add an existing user to a more convenient variable
# Alernatively, if we don't want to store the entire user object in the session,
# we could go to the db here.
#
exports.populateUser = (req, res, next) ->
    req.user = req.session.user
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
