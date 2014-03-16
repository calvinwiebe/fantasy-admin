# These are API routes for fetching
# resources
uuid    = require 'node-uuid'
moniker = require 'moniker'
_       = require 'lodash'

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
        type: 'n/a'
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
        type: req.body.type
        users: _.uniq(req.body.users) or []
        rounds: []

    r.table('pools').insert(doc).run conn, (err, results) ->
        parseRoundDefinitions conn, r, req.body.type, doc.id, ->
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

parseRoundDefinitions = (conn, r, poolTypeId, poolId, done) ->
    r.table('poolTypes').get(poolTypeId).run conn, (err, poolType) ->
        _.each poolType.rounds, (round) ->
            createRound conn, r, round, poolId
        done()

createRound = (conn, r, round, poolId) ->
    id = uuid.v4()

    for series in [1..round.numberOfSeries]
        createSeries conn, r, round.gamesPerSeries

    doc =
        id: id
        name: round.name
        date: new Date()
        state: 0
        series: []

    r.table('rounds').insert(doc).run conn, (err, results) ->
        console.log "created round #{round.name}"

createSeries = (conn, r, numberOfGames) ->
    id = uuid.v4()

    gameIds = []

    for i in [1..numberOfGames]
        gameIds.push uuid.v4()

    games = _.map games, (gameId) ->
        id: gameId

    r.table('games').insert(games).run conn, (err, results) ->
        console.log "created #{numberOfGames} games"

    doc =
        id: id
        team1: null
        team2: null
        games: gameIds

    r.table('series').insert(doc).run conn, (err, results) ->
        console.log "created a series with #{numberOfGames} games"