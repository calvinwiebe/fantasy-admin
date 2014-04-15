# Common functions to get access to the rethink driver
#
r           = require 'rethinkdb'
{db}        = require '../config'
dbConfig    = db

# Add the rethink connection objects to the request
#
exports.getConnection = (done) ->
    r.connect host: dbConfig.address, port: dbConfig.port,
        (err, conn) ->
            return done err if err?
            conn.use dbConfig.adminDb.name
            done null, {conn, r}
