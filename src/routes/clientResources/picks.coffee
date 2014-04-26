# Picks
_         = require 'lodash'
async     = require 'async'
{events}  = require '../../lib'

# GET. can be filtered by user id
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    user = req.query.user
    filter = -> true

    getPicks = (filter) ->
        r.table('picks').filter(filter).run conn, (err, results) ->
            results.toArray (err, picks) ->
                res.json picks

    if user?
        r.table('users').get(user)('picks').run conn, (err, picks) ->
            getPicks (pick) ->
                r.expr(picks).contains(pick('id'))
    else
        getPicks filter

exports.new = (req, res, next) ->
exports.create = (req, res, next)->
    {conn, r} = req.rethink

    # send a no-content when there isn't a user, or no data, as we have not done anything
    return res.send 204 if !req.user? or _.isEmpty req.body

    data = req.body
    rounds = []
    docs = if _.isArray data then data else [ data ]
    docs.forEach (doc) ->
        rounds.push doc.round
        doc.user = req.user.id

    expired = false
    # just to be safe... we are going to make sure that every pick a user sends is for a round that hasn't expired
    async.each(
        _.uniq rounds
        (round, done) ->
            r.table('rounds').get(round).run conn, (err, results) ->
                date = results?.date
                if date and new Date(date).getTime() < new Date().getTime()
                    expired = true
                done()
        ->
            if !expired
                r.table('picks').insert(docs).run conn, (err, results) ->
                    res.send docs
                process.nextTick ->
                    # notify the system of new picks
                    events.getEventBus('email').emit 'email',
                        type: 'newPicks'
                        user: req.user.id
                        round: data[0].round
            else
                res.status 418
                res.json error: 'Deadline PAST'
    )

exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('picks').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
    {conn, r} = req.rethink

    r.table('picks').get(req.param('id')).update(req.body).run conn, (err, results) ->
        res.send req.body

exports.destroy = (req, res, next)->