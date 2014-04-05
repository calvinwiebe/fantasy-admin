# Results

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('results')
    .run conn, (err, cursor) ->
        cursor.toArray (err, results) ->
            res.send results

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    result =
        categoryId: req.body.categoryId
        seriesId: req.body.seriesId
        value: req.body.value

    if req.body.gameNumber? then result.gameNumber = parseInt req.body.gameNumber, 10

    r.table('results').insert(result).run conn, (err, results) ->
            res.send results.generated_keys[0]

exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
