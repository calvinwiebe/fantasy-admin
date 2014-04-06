# These are API routes for fetching
# resources

# GET. can be filtered by round id.
# TODO: make all the filterable routes use something common to do so.
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    round = req.query.round
    filter = -> true

    getSeries = (filter) ->
        r.table('series').filter(filter).run conn, (err, results) ->
            results.toArray (err, series) ->
                res.json series

    if round?
        r.table('rounds').get(round)('series').run conn, (err, series) ->
            getSeries (s) ->
                answer = series? and r.expr(series).contains(s('id'))
                if not answer
                    console.log 'Couldnt find round, it is hard coded in
                        picks.coffee for now, probs need to change it
                    '
                answer
    else
        getSeries filter

exports.new = (req, res, next) ->
exports.create = (req, res, next)->
exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
    {conn, r} = req.rethink

    r.table('series').get(req.param('id')).update(req.body).run conn, (err, results) ->
        res.send results

exports.destroy = (req, res, next)->
