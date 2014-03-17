# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('series').run conn, (err, results) ->
        results.toArray (err, series) ->
            res.json series

# GET - randomly creates a new round
exports.new = (req, res, next) ->
    {conn, r} = req.rethink

    doc =
        id: uuid.v4()
        name: moniker.choose()
        categories: []

    r.table('series').insert(doc).run conn, (err, results) ->
        res.send results

exports.create = (req, res, next)->
    {conn, r} = req.rethink

    id = uuid.v4()

    doc =
        id: id
        name: req.body.name
        categories: []

    r.table('series').insert(doc).run conn, (err, results) ->
        res.send doc

exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).update(req.body).run conn, (err, results) ->
        res.send results

exports.destroy = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).delete().run conn, (err, results) ->
        res.send results

