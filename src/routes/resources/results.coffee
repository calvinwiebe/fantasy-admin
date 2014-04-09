# Results

# GET
# Can be filtered by the series and game
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    series = req.query.series
    game = req.query.game
    filter = -> true

    getResults = (filter) ->
        r.table('results').filter(filter).run conn, (err, dbResults) ->
            dbResults.toArray (err, results) ->
                res.json results

    if series? and game?
        getResults (result) ->
            result('game').eq(game)
    else if series?
        getResults (result) ->
            result('series').eq(series)
    else
        getResults filter

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    result = req.body
    if req.body.game? then result.game = parseInt req.body.game, 10

    r.table('results').insert(result).run conn, (err, results) ->
        res.json result

exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
