# Authentication routes
#
{hashPassword} = require '../lib'

# Login in a user
#
exports.login = (req, res, next) ->
    name = req.body.user
    password = req.body.password

    {conn, r} = req.rethink

    attemptedHash = hashPassword password

    filter = (user) ->
        user('name').eq(name).or(user('email').eq(name))

    r.table('users').filter(filter).run conn,
        (err, results) ->
            return next err if err?
            results.toArray (err, [user]) ->
                if err?
                    next err
                else if not user or user.password isnt attemptedHash
                    next()
                else
                    # user successfully logged in
                    req.session.user = user
                    next()

# Depending on the user, send them to the appropriate
# url
#
exports.redirect = (req, res) ->
    if req.session.user?.permission is 'admin'
        res.redirect '/admin/dashboard'
    else if req.session.user?.permission is 'pool'
        res.redirect '/pool/dashboard'
    else
        res.redirect '/'

# Log a user our
#
exports.logout = (req, res, next) ->
    req.session.user = null
    next()
