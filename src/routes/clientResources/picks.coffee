# Picks
_ = require 'lodash'

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
    docs = if _.isArray data then data else [ data ]
    docs.forEach (doc) -> doc.user = req.user.id

    r.table('picks').insert(docs).run conn, (err, results) ->
        res.send docs

exports.show = (req, res, next)->
    {conn, r} = req.rethink

    r.table('picks').get(req.param('id')).run conn, (err, results) ->
        res.send results

exports.update = (req, res, next)->
    {conn, r} = req.rethink

    r.table('picks').get(req.param('id')).update(req.body).run conn, (err, results) ->
        res.send req.body

exports.destroy = (req, res, next)->