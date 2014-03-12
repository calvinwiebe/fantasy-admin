# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'

# GET. can be filtered by pool id.
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    pool = req.query.pool
    filter = -> true

    getUser = (filter) ->
        r.table('users').filter(filter).run conn, (err, results) ->
            results.toArray (err, users) ->
                res.json users

    if pool?
        r.table('pools').get(pool)('users').run conn, (err, users) ->
            getUser (user) ->
                r.expr(users).contains(user('id'))
    else
        getUser filter


# GET - randomly creates a new pool
exports.new = (req, res, next) ->

# POST to create a user. They will also be attached to a pool.
# TODO - check if user already exists.
exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    email = req.body.email
    pool = req.body.pool

    doc =
        id: uuid.v4()
        email: email
        name: 'anon'
        permission: 'pool'
        password: ''

    r.table('users').insert(doc).run conn, (err, result) ->
        r.table('users').get(doc.id).run conn, (err, user) ->
            res.send user

exports.show = (req, res, next) ->
    {conn, r} = req.rethink

# PUT
# TODO - check if user already exists.
exports.update = (req, res, next) ->
    {conn, r} = req.rethink

    email = req.body.email
    id = req.body.id
    r.table('users').get(id).update({email}).run conn, (err, user) ->
        r.table('users').get(id).run conn, (err, user) ->
            res.send user

exports.destroy = (req, res, next) ->
    {conn, r} = req.rethink

