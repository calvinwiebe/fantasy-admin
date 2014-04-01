async       = require 'async'
roundUtils  = require './roundUtils'

exports.create = (conn, r, pool, cb) ->
    parsePoolType conn, r, pool, (ids) ->
        pool.rounds = ids

        r.table('pools').insert(pool).run conn, (err, results) ->
            cb err, results.generated_keys[0]

parsePoolType = (conn, r, pool, cb) ->
    roundIds = []
    r.table('poolTypes').get(pool.type).run conn, (err, poolType) ->
        async.each(
            poolType.rounds
            (round, done) ->
                roundUtils.create conn, r, round, (id) ->
                    roundIds.push id
                    done()
            ->
                cb roundIds
        )
