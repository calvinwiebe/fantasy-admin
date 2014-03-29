# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'

# GET - can be filtered by pool id
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    pool = req.query.pool
    filter = -> true

    getRounds = (filter) ->
        r.table('rounds').filter(filter).run conn, (err, results) ->
            results.toArray (err, rounds) ->
                res.json rounds

    if pool?
        r.table('pools').get(pool)('rounds').run conn, (err, rounds) ->
            getRounds (round) ->
                r.expr(rounds).contains(round('id'))
    else
        getRounds filter


# GET - randomly creates a new round
exports.new = (req, res, next) ->
    {conn, r} = req.rethink

    doc =
        id: uuid.v4()
        date: new Date(2014, 4, 2, 17)
        name: moniker.choose()
        series: []

    r.table('rounds').insert(doc).run conn, (err, results) ->
        res.send results

exports.create = (req, res, next)->
    {conn, r} = req.rethink

    id = uuid.v4()

    doc =
        id: id
        date: new Date(2014, 4, 2, 17)
        name: req.body.name
        series: []

    r.table('rounds').insert(doc).run conn, (err, results) ->
        res.send doc

exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('rounds').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
    {conn, r} = req.rethink

    r.table('rounds').get(req.param('id')).update(req.body).run conn, (err, results) ->
        res.send results

exports.destroy = (req, res, next)->
    {conn, r} = req.rethink

    r.table('rounds').get(req.param('id')).delete().run conn, (err, results) ->
        res.send results

