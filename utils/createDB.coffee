#!/usr/bin/env node

# Tool to create an admin user (admin/admin).

r               = require 'rethinkdb'
{db}            = require '../src/config'
dbService       = require '../src/services/db'
dbConfig        = db
{poolTypes}     = require './data/poolTypes'
{teams}         = require './data/teams'
{categories}    = require './data/categories'

setPoolTypes = (conn, done) ->
    r.table('poolTypes').insert(poolTypes).run conn, (err, res) ->
        if err?
            console.log "Received an error inserting poolTypes data #{err}"
            process.exit -1
        done()

setTeams = (conn, done) ->
    r.table('teams').insert(teams).run conn, (err, res) ->
        if err?
            console.log "Received an error inserting team data #{err}"
            process.exit -1
        done()

setCategories = (conn, done) ->
    r.table('categories').insert(categories).run conn, (err, res) ->
        if err?
            console.log "Received an error inserting categories #{err}"
            process.exit -1
        done()

r.connect host: dbConfig.address, port: dbConfig.port,
    (err, conn) ->
        if err?
            console.log "Received an error connecting to the db #{err}"
            process.exit -1

        conn.use dbConfig.adminDb.name

        r.dbDrop('admin').run conn, (err, res) ->
            if err?
                console.log "Received an error dropping the db #{err}"

            dbService.initialize ->
                console.log 'Successfully created tables'
                setPoolTypes conn, ->
                    console.log "Successfully inserted pool types data"
                    setTeams conn, ->
                        console.log "Successfully inserted teams data"
                        setCategories conn, ->
                            console.log "Successfully inserted categories data"
                            process.exit 0
