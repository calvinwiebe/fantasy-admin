# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'
_ = require 'lodash'

# GET - can be filtered by pool id
#
# round dates are saved as js Date objects. Map them to a timestamp
# for the front end.
#
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    pool = req.query.pool
    filter = -> true

    getRounds = (filter) ->
        r.table('rounds').filter(filter).run conn, (err, results) ->
            results.toArray (err, rounds) ->
                min = _.chain(rounds)
                    .filter((r) -> not r.completed)
                    .pluck('order')
                    .min()
                    .value()
                rounds.forEach (round) ->
                    round.date = round.date?.getTime()
                    round.disabled = \
                        round.completed or round.order isnt min
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
        date: new Date
        name: moniker.choose()
        series: []

    r.table('rounds').insert(doc).run conn, (err, results) ->
        res.send results

exports.create = (req, res, next)->
    {conn, r} = req.rethink

    id = uuid.v4()

    doc =
        id: id
        date: new Date
        name: req.body.name
        series: []

    r.table('rounds').insert(doc).run conn, (err, results) ->
        res.send doc

exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('rounds').get(req.param('id')).run conn, (err, results) ->
        results.date = results.date.getTime()
        res.send results

# Round dates come in as timestamps; remap them to a js Date on
# save
#
exports.update = (req, res, next)->
    {conn, r} = req.rethink

    doc = req.body
    # todo: timezones? probably not necessary right now.
    doc.date = new Date req.body.date

    r.table('rounds').get(req.param('id')).update(doc).run conn, (err, results) ->
        res.send results

exports.destroy = (req, res, next)->
    {conn, r} = req.rethink

    r.table('rounds').get(req.param('id')).delete().run conn, (err, results) ->
        res.send results

