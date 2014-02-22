# Authentication routes
#
crypto = require 'crypto'

# Login in a user
#
exports.login = (rootUrl, successUrl) ->
    (req, res, next) ->
        name = req.body.user
        password = req.body.password

        {conn, r} = req.rethink

        attemptedHash = crypto.createHash('sha256')
            .update(password)
            .digest('hex')

        r.table('users').filter(name: name).run conn,
            (err, results) ->
                return next err if err?
                results.toArray (err, [user]) ->
                    if err?
                        return next err
                    else if not user or user.password isnt attemptedHash
                        return res.redirect rootUrl
                    else
                        # user successfully logged in
                        req.session.user = user.name
                        console.log 'successful log in'
                        console.log req.session
                        res.redirect successUrl

# Log a user our
#
exports.logout = (rootUrl) ->
    (req, res, next) ->
        req.session.user = null
        res.redirect rootUrl
