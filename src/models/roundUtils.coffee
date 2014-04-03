async       = require 'async'
seriesUtils = require './seriesUtils'

exports.create = (conn, r, round, cb) ->
    doc =
        name: round.name
        date: null
        state: 0
        order: round.order
        completed: false
        series: []

    async.times(
        round.numberOfSeries
        (index, done) ->
            conference = if round.numberOfSeries > 1 then index % 2 else -1
            seriesUtils.create conn, r, round.gamesPerSeries, conference, (id) ->
                doc.series.push id
                done()
        ->
            r.table('rounds').insert(doc).run conn, (err, results) ->
                cb results.generated_keys[0]
    )