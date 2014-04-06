async       = require 'async'
roundUtils  = require './roundUtils'

exports.create = (conn, r, pool, cb) ->
    r.table('pools').insert(pool).run conn, (err, results) ->
        cb err, results.generated_keys[0]

exports.get = get = (conn, r, id, cb) ->
    r.table('pools').get(id).run conn, (err, pool) ->
        cb err, pool

exports.update = update = (conn, r, pool, cb) ->
    r.table('pools').get(pool.id).update(pool).run conn, (err) ->
        get conn, r, pool.id, cb

exports.startPool = (conn, r, pool, cb) ->
    parsePoolType conn, r, pool, (ids) ->
        pool.rounds = ids
        update conn, r, pool, cb

exports.endPool = (conn, r, pool, cb) ->
    update conn, r, pool, cb

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
