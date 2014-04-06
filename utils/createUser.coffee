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
    .option('-t, --type [type]', 'user type')
    .option('-e, --email <email>', "user's email")
    .option('-p, --password <password>', 'password to be hashed to db')
    .parse process.argv

userMap =
    'user':
        permission: 'pool'
    'admin':
        permission: 'admin'

hashPass = (pass) ->
    shasum = crypto.createHash 'sha256'
    hashed = shasum.update(pass).digest 'hex'
    hashed

getExisting = (r, conn, email, done) ->
    r.table('users').filter(email: email).run conn,
        (err, results) ->
            results.toArray (err, [user]) ->
                done null, user

# setup the db and tables if they haven't been created yet.
# Then add the user to the db.
#
createUser = ({type, email, password}, done) ->
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

                            getExisting r, conn, email, (err, user) ->
                                if user?
                                    user.password = hashed
                                    query = r.table('users').replace(user)
                                else
                                    doc =
                                        id: uuid.v4()
                                        password: hashed
                                        permission: userMap[type].permission
                                        email: email
                                    query = r.table('users').insert(doc)

                                query.run conn, (err, res) ->
                                    if err?
                                        console.log "Received an error creating user #{err}"
                                        process.exit -1
                                    return done()

{type, email, password} = commander

type ?= 'user'

unless email? and password?
    console.log 'email and password are required.'
    process.exit -1

createUser {type, email, password}, ->
    console.log "Successfully created user #{email} with password #{password}"
    process.exit 0
