#!/usr/bin/env node

# Tool to create an admin user with a password. This
# will take a `user` and `password` argument, hash the
# password, and stick it into the db.

commander   = require 'commander'
r           = require 'rethinkdb'
{db}        = require '../src/config'
dbService   = require '../src/services/db'
dbConfig    = db
crypto      = require 'crypto'
uuid        = require 'node-uuid'

commander
    .version('0.0.1')
    .usage(' <user> <password>')
    .parse process.argv

hashPass = (pass) ->
    shasum = crypto.createHash 'sha256'
    hashed = shasum.update(pass).digest 'hex'
    console.log 'Created password ' + hashed
    hashed

# setup the db and tables if they haven't been created yet.
# Then add the user to the db.
#
createAdmin = (user, password, done) ->
    r.connect host: dbConfig.address, port: dbConfig.port,
        (err, conn) ->
            if err?
                console.log "Received an error connecting to the db #{err}"
                process.exit -1

            conn.use 'admin'

            dbService.createDatabase conn, dbConfig.adminDb.name,
                (err) ->
                    dbService.createTable conn, 'users',
                        (err) ->
                            hashed = hashPass password

                            doc =
                                id: uuid.v4()
                                name: user
                                password: hashed
                                permission: 'admin'

                            r.table('users').insert(doc).run conn, (err, res) ->
                                if err?
                                    console.log "Received an error creating user #{err}"
                                    process.exit -1
                                done()

if commander.args.length < 2
    console.log 'Arguments must be of length 2: <user> <password>'
    process.exit -1

[user, password] = commander.args

createAdmin user, password, ->
    console.log "Successfully created user #{user}"
    process.exit 0
