# Categories

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('categories')
    .run conn, (err, cursor) ->
        cursor.toArray (err, categories) ->
            res.send categories

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
