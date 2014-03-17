uuid        = require 'node-uuid'
_           = require 'lodash'
async       = require 'async'

exports.create = (conn, r, pool, done) ->
    parseRoundDefinitions conn, r, pool, (ids) ->
        pool.rounds = ids
        r.table('pools').insert(pool).run conn, (err, results) ->
            done()

parseRoundDefinitions = (conn, r, pool, cb) ->
    roundIds = []
    console.log arguments
    r.table('poolTypes').get(pool.type).run conn, (err, poolType) ->
        async.each(
            poolType.rounds
            (round, done) ->
                createRound conn, r, round, (id) ->
                    roundIds.push id
                    done()
            () ->
                cb roundIds
        )

createRound = (conn, r, round, cb) ->
    doc =
        name: round.name
        date: null
        state: 0
        series: []

    async.times(
        round.numberOfSeries
        (index, done) ->
            createSeries conn, r, round.gamesPerSeries, (id) ->
                doc.series.push id
                done()
        () ->
            r.table('rounds').insert(doc).run conn, (err, results) ->
                cb results.generated_keys[0]
    )

createSeries = (conn, r, numberOfGames, cb) ->
    doc =
        team1: null
        team2: null
        games: []

    async.times(
        numberOfGames
        (index, done) ->
            r.table('games').insert({}).run conn, (err, results) ->
                doc.games.push results.generated_keys[0]
                done()
        () ->
            r.table('series').insert(doc).run conn, (err, results) ->
                cb results.generated_keys[0]
    )