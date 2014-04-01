# These are API routes for fetching
# resources
_           = require 'lodash'

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    conference = req.query.conference
    
    getTeams = (filter) ->
        r.table('teams').filter(filter).run conn, (err, results) ->
            results.toArray (err, teams) ->
                res.json teams

    if conference?
        getTeams conference: parseInt conference, 10
    else
        getTeams true

exports.new = (req, res, next) ->
exports.create = (req, res, next)->
exports.show = (req, res, next) ->
    {conn, r} = req.rethink
    r.table('teams').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
exports.destroy = (req, res, next) ->
