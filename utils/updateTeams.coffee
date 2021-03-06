#!/usr/bin/env node

# Tool to create an admin user (admin/admin).

r               = require 'rethinkdb'
{db}            = require '../src/config'
dbService       = require '../src/services/db'
dbConfig        = db
_               = require 'lodash'
{teams}         = require './data/teams'

getTeams = (conn, done) ->
    r.table('teams').run conn, (err, results) ->
        results.toArray (err, teams) ->
            done teams

updateTeams = (conn, done) ->
    getTeams conn, (existingTeams) ->
        if existingTeams.length isnt teams.length
            console.error "You have to enter the same number of teams that already exist"
            process.exit -1

        _.each teams, (team) ->
            match = _.findWhere existingTeams, name: team.name
            
            if match?
                team.id = match.id
            else
                console.error "You cannot add new teams, only update existing ones"
                process.exit -1
            console.log team.shortName, team.id
        
        r.table('teams').delete().run conn, (err, res) ->
            if err?
                console.log "Received an error removing old team data #{err}"
                process.exit -1
            r.table('teams').insert(teams).run conn, (err, res) ->
                if err?
                    console.log "Received an error inserting new team data #{err}"
                    process.exit -1
                done()

dbService.connect (err, conn) ->
    if err?
        console.log "Received an error connecting to the db #{err}"
        process.exit -1

    conn.use dbConfig.adminDb.name
    
    updateTeams conn, ->
        console.log "Successfully updated teams data"
        process.exit 0
