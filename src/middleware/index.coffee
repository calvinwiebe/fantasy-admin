# Express middleware for our Admin app
#
r           = require 'rethinkdb'
{db}        = require '../config'
dbConfig    = db

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

exports.requireUser = (rootUrl) ->
    (req, res, next) ->
        console.log 'running requireUser'
        return res.redirect rootUrl unless req.session?.user
        next()
