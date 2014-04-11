# Util to operate on the `pendingPicks` table
async = require 'async'
poolUtils = require './poolUtils'

filter = (context, round, cb) ->
    poolUtils.filter {
        context
        filter: (pool) -> pool('rounds').contains(round.id)
        cb
    }

# context expects
# `conn`, `r`
exports.create = (context, done) ->
    {round} = context
    return done null unless round?

    async.waterfall [
        # get the pool that contains this round
        (cb) -> filter context, round, cb
        # grab all the users of the pool and save the batch to
        # the db
        ([pool], cb) ->
            pendingPicks = pool.users.map (user) ->
                user: user
                round: round.id
                pool: pool.id
            {conn, r} = context
            r.table('pendingPicks').insert(pendingPicks).run conn, (err, result) ->
                cb err, result
    ], (err, result) ->
        done err

# context expects
# `conn`, `r`
exports.destroy = (context, done) ->
    {round} = context
    return done null unless round?

    async.waterfall [
        # get the pool that contains this round
        (cb) -> filter context, round, cb
        # grab all the users of the pool and blow away their
        # pending picks
        ([pool], cb) ->
            {conn, r} = context
            r.table('pendingPicks').filter((pick) -> pick('round').eq(round.id)).delete().run conn, (err, result) ->
                cb err, result
    ], (err, result) ->
        done err
