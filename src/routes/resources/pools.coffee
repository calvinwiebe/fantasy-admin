# These are API routes for fetching
# resources
_           = require 'lodash'
moniker     = require 'moniker'
poolUtils   = require '../../models/poolUtils'

# GET
# Can be accessed by both admin and users. When a user with `pools` permission
# is accessing it, filter the response to only be pools that they belong to.
#
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    getPools = (filter) ->
        r.table('pools').filter(filter).run conn, (err, results) ->
            results.toArray (err, pools) ->
                res.json pools

    if req.user? and req.user.permission isnt 'admin'
        getPools (pool) ->
            pool('users').contains(req.user?.id)
    else
        getPools -> true 

# GET - randomly creates a new pool
exports.new = (req, res, next) ->
    {conn, r} = req.rethink

    pool =
        name: moniker.choose()
        type: 'n/a'
        state: 0
        users: []
        rounds: []

    poolUtils.create conn, r, pool, (err, results) ->
        res.send results

exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    pool =
        name: req.body.name
        type: req.body.type
        state: 0
        users: _.uniq(req.body.users) or []
        rounds: []
        categories: []

    poolUtils.create conn, r, pool, (err, id) ->
        pool.id = id
        res.send pool

exports.show = (req, res, next) ->
    {conn, r} = req.rethink

    poolUtils.get conn, r, req.param('id'), (err, pool) ->
        res.send pool

exports.update = (req, res, next) ->
    {conn, r} = req.rethink

    switch req.body.state
        when 0
            poolUtils.update conn, r, req.body, (err, pool) ->
                res.send pool
        when 1
            poolUtils.startPool conn, r, req.body, (err, pool) ->
                res.send pool
        when 2
            poolUtils.endPool conn, r, req.body, (err, pool) ->
                res.send pool

exports.destroy = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('pools').get(req.param('id')).delete().run conn, (err, results) ->
        res.send results
    #TODO: we need to cascade down and delete EVERYTHING, rounds, series, results
