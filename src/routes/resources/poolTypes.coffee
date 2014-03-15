# Pool Types

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('poolTypes')
    .run conn, (err, cursor) ->
        cursor.toArray (err, types) ->
            res.send types

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
