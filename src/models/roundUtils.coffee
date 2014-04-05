async       = require 'async'
seriesUtils = require './seriesUtils'

exports.create = (conn, r, round, cb) ->
    doc =
        name: round.name
        date: null
        state: if round.order is 0 then 1 else 0
        order: round.order
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