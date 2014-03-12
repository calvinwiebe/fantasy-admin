# These are API routes for fetching
# resources
uuid = require 'node-uuid'
moniker = require 'moniker'
_       = require 'lodash'

# get users by email
#
getExisting = (email, conn, r, done) ->
    filter = (user) ->
        user('email').eq(email).and user('permission').eq('pool')

    r.table('users').filter(filter).run conn, (err, results) ->
        results.toArray (err, users) ->
            done err, users

### CRUD ###

# Create
# POST to create a user. They will also be attached to a pool.
exports.create = (req, res, next) ->
    {conn, r} = req.rethink

    email = req.body.email
    pool = req.body.pool

    getExisting email, conn, r, (err, users) ->
        if users.length is 1
            res.send users[0]
        else if users.length > 1
            # this should not happen, yikes
            res.status 500
            res.send msg: 'Double email encountered.'
        else
            doc =
                id: uuid.v4()
                email: email
                name: 'anon'
                permission: 'pool'
                password: ''

            r.table('users').insert(doc).run conn, (err, result) ->
                r.table('users').get(doc.id).run conn, (err, user) ->
                    res.send user

# GET - randomly creates a new pool
exports.new = (req, res, next) ->

### READ ###

exports.show = (req, res, next) ->
    {conn, r} = req.rethink

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

### UPDATE ###

# PUT
exports.update = (req, res, next) ->
    {conn, r} = req.rethink

    email = req.body.email
    id = req.body.id
    r.table('users').get(id).update({email}).run conn, (err, user) ->
        r.table('users').get(id).run conn, (err, user) ->
            res.send user

### DELETE ###

exports.destroy = (req, res, next) ->
    {conn, r} = req.rethink
