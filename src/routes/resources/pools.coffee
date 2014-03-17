# These are API routes for fetching
# resources
_           = require 'lodash'
moniker     = require 'moniker'
poolUtils   = require '../../models/poolUtils'

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('pools').run conn, (err, results) ->
        results.toArray (err, pools) ->
            res.json pools

# GET - randomly creates a new pool
exports.new = (req, res, next) ->
    {conn, r} = req.rethink

    pool =
        name: moniker.choose()
        type: 'n/a'
        users: []
        rounds: []

    poolUtils.create conn, r, pool, (err, results) ->
        res.send results

exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    pool =
        name: req.body.name
        type: req.body.type
        users: _.uniq(req.body.users) or []
        rounds: []

    poolUtils.create conn, r, pool, (err, results) ->
        pool.id = results.generated_keys[0]
        res.send pool

exports.show = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('pools').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('pools').get(req.param('id')).update(req.body).run conn, (err, results) ->
        r.table('pools').get(req.param('id')).run conn, (err, pool) ->
            res.send pool

exports.destroy = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('pools').get(req.param('id')).delete().run conn, (err, results) ->
        res.send results
