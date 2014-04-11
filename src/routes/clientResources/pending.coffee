# Pending Picks

# GET
# Can be filtered by a user id
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    user = req.user?.id
    filter = if user? then { user } else -> true

    r.table('pendingPicks').filter(filter).run conn, (err, results) ->
        results.toArray (err, pendingPicks) ->
            # this should only ever be one, if it isn't badness
            if pendingPicks.length > 1
                console.warn "pending picks for user #{user} have exceeded one!"
                data = pendingPicks
            else if pendingPicks.length is 0
                data = {}
            else
                data = pendingPicks[0]
            res.json data

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
    {conn, r} = req.rethink

    id = req.param 'id'

    r.table('pendingPicks').get(id).delete().run conn, (err) ->
        next err if err?
        res.send 200
