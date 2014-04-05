# Categories

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    pool = req.query.pool
    filter = -> true

    getCategories = (filter) ->
        r.table('categories').filter(filter).run conn, (err, results) ->
            results.toArray (err, categories) ->
                res.json categories

    if pool?
        r.table('pools').get(pool)('categories').run conn, (err, categories) ->
            getCategories (category) ->
                r.expr(categories).contains(category('id'))
    else
        getCategories filter

exports.new = (req, res, next) ->
exports.create = (req, res, next) ->
exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
