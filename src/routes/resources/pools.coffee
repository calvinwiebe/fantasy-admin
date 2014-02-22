# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'

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

    r.table('pools').insert(doc).run conn, (err, results) ->
        res.send results

exports.create = ->
exports.show = ->
exports.destroy = ->

