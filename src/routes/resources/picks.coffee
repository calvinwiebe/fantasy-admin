# Picks

# GET. can be filtered by user id
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    user = req.query.user
    filter = -> true

    getPicks = (filter) ->
        r.table('picks').filter(filter).run conn, (err, results) ->
            results.toArray (err, picks) ->
                res.json picks

    if user?
        r.table('users').get(user)('picks').run conn, (err, picks) ->
            getPicks (pick) ->
                r.expr(picks).contains(pick('id'))
    else
        getPicks filter

exports.new = (req, res, next) ->
exports.create = (req, res, next)->
    {conn, r} = req.rethink

    console.log 'Got a pick to save'
    console.log req.body

exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).update(req.body).run conn, (err, results) ->
        res.send results

exports.destroy = (req, res, next)->