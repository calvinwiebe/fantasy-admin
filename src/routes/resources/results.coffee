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

    result = req.body
    if req.body.game? then result.game = parseInt req.body.game, 10

    r.table('results').insert(result).run conn, (err, results) ->
            res.send results.generated_keys[0]

exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
