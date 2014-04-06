# Authentication routes
#
{hashPassword} = require '../lib'

#
# Login in a user
#
login = (req, res, next) ->
    email = req.body.email
    password = req.body.password

    {conn, r} = req.rethink

    attemptedHash = hashPassword password

    filter = (user) ->
        user('email').eq(email)

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
                    # this will cause client-sessions to add a `Set-Cookie` header with
                    # the user info in it
                    delete user.password
                    delete user.plainPassword
                    req.session.user = user
                    next()

# Log a user our
#
logout = (req, res, next) ->
    req.session.user = null
    next()

# Depending on the user, send them to the appropriate
# url
#
exports.forward = forward = (req, res, next) ->
    if req.session.user?.permission is 'admin'
        res.redirect '/admin/dashboard'
    else if req.session.user?.permission is 'pool'
        res.redirect '/pool/dashboard'
    else
        next()

# Go home
#
exports.home = home = (req, res) ->
    res.redirect '/'

exports.login = [
    login
    forward
    home
]

exports.logout = [
    logout
    home
]


