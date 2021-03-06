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
                    req.session.user = null
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

# Reset a user's password
#
exports.passwordReset = (req, res, next) ->
    {currentPassword, newPassword, confirmPassword} = req.body
    {conn, r} = req.rethink

    if newPassword isnt confirmPassword
        res.status 400
        return res.json code: -1, error: 'Passwords do not match.'
    newHashed = hashPassword newPassword
    r.table('users')
    .get(req.user.id)
    .update((user) ->
        r.branch user('password').eq(hashPassword(currentPassword)), password: newHashed, {}
    ).run conn, (err, results) ->
        return next err if err?
        if results.unchanged is 1
            res.status 400
            res.json code: -1, error: 'Current password is incorrect.'
        else
            res.json code: 0, msg: 'Successfully updated password.'

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


