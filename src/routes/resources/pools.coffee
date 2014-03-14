# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'
_ = require 'lodash'

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('pools').run conn, (err, results) ->
        results.toArray (err, pools) ->
            res.json pools

# GET - randomly creates a new pool
exports.new = (req, res, next) ->
    {conn, r} = req.rethink

    doc =
        id: uuid.v4()
        name: moniker.choose()
        users: []
        rounds: []

    r.table('pools').insert(doc).run conn, (err, results) ->
        res.send results

exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    id = uuid.v4()

    doc =
        id: id
        name: req.body.name
        users: _.uniq(req.body.users) or []
        rounds: []

    r.table('pools').insert(doc).run conn, (err, results) ->
        res.send doc

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

