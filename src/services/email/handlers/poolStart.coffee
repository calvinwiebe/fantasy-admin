# Compile the data for a `Pool Start` email
#
async           = require 'async'
config          = require '../../../config'
poolUtils       = require '../../../models/poolUtils'
{rethink}       = require '../../../lib'

getUsers = ({conn, r, pool}, done) ->
    r.table('users').filter(
        (user) -> r.expr(pool.users).contains(user('id'))
    ).run conn,
        (err, results) ->
            return done err if err?
            results.toArray done

module.exports = (data, done) ->
    async.waterfall [
        # get a rethink connection
        (cb) -> rethink.getConnection cb
        # get the pools
        ({conn, r}, cb) -> poolUtils.get conn, r, data.pool, (err, pool) ->
            cb err, {conn, r, pool}
        # get the full users in the pool
        ({conn, r, pool}, cb) -> getUsers {conn, r, pool}, (err, users) ->
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
