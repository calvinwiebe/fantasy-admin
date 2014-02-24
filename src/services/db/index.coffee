# Contains utility operations to be performed on the db
#
r   = require 'rethinkdb'
{db}     = require '../../config'
dbConfig = db
# TODO: remove async, either use streamline, homegrow, or ES6 generators
async    = require 'async'

# Create a database helper
#
exports.createDatabase = createDatabase = (conn, name, cb) ->
    r.dbCreate(name).run conn, (err, results) ->
        if err?.name is 'RqlRuntimeError'
            cb()
        else if err?
            cb err
        else
            console.log "Created db #{name} in rethinkDB"
            cb()

# Create a table iterator helper
#
exports.createTable = createTable = (conn, table, cb) ->
    r.tableCreate(table).run conn, (err, results) ->
        if err?.name is 'RqlRuntimeError'
            cb()
        else if err?
            cb err
        else
            console.log "Created table #{table} in #{db}"
            cb()

# Create any necessary databases and tables
# if they aren't yet created.
#
exports.initialize = (done) ->
    console.log "Initializing db and tables"
    r.connect host: dbConfig.address, port: dbConfig.port,
        (err, conn) ->
            return throw err if err?
            createDatabase conn, dbConfig.adminDb.name,
                (err) ->
                    conn.use dbConfig.adminDb.name
                    async.each \
                        dbConfig.adminDb.tables, createTable.bind(null, conn), (err) ->
                            return throw err if err?
                            done()