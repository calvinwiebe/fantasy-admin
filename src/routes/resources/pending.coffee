# Pending Picks

# GET
# Can be filtered by a user id
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    user = req.query.user
    filter = if user? then { user } else true

    r.table('pendingPicks').filter(filter).run conn, (err, results) ->
        results.toArray (err, pendingPicks) ->
            res.json pending

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
