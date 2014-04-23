# Compile the data for a `Pool Start` email
#
async                   = require 'async'
config                  = require '../../../config'
poolUtils               = require '../../../models/poolUtils'
{rethink, hashPassword} = require '../../../lib'
moniker                 = require 'moniker'

# Get all the users for the pool.
#
getUsers = ({conn, r, pool}, done) ->
    r.table('users').filter(
        (user) -> r.expr(pool.users).contains(user('id'))
    ).run conn,
        (err, results) ->
            return done err if err?
            results.toArray done

# create the passwords here and add them to the email. Doing it
# this way will mean their plain passwords will only live during
# this execution, and in the emails.
#
generatePasswords = ({conn, r, users}, done) ->
    passwords = {}
    users.forEach (user) ->
        return unless !user.password?
        plain = moniker.choose()
        passwords[user.id] = plain
        user.password = hashPassword plain
    async.forEach users, (user, cb) ->
        r.table('users').update(user).run conn, (err, results) ->
            cb err
    , (err, results) ->
        done err, users.map (user) ->
            return user unless passwords[user.id]
            user.plainPassword = passwords[user.id]
            user

module.exports = (data, done) ->
    async.waterfall [
        # get a rethink connection
        (cb) -> rethink.getConnection cb
        # get the pools
        ({conn, r}, cb) -> poolUtils.get conn, r, data.pool, (err, pool) ->
            cb err, {conn, r, pool}
        # get the full users in the pool
        ({conn, r, pool}, cb) -> getUsers {conn, r, pool}, (err, users) ->
            cb err, {conn, r, pool, users}
        # create the passwords for the users
        ({conn, r, pool, users}, cb) -> generatePasswords {conn, r, users},
            (err, users) ->
                cb err, {pool, users}
    ], (err, results={}) ->
        return done err, results if err
        {users, pool} = results
        done null,
            recipients: users
            locals:
                pool: pool.name
                server: config.email.server
            subject: "You have been added to the #{pool.name} pool!"
