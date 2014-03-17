# Categories
uuid = require 'node-uuid'
moniker = require 'moniker'
_ = require 'lodash'

# GET
exports.index = (req, res, next) ->
    {conn, r} = req.rethink

    r.table('categories')
    .run conn, (err, cursor) ->
        cursor.toArray (err, categories) ->
            res.send categories

# GET - randomly creates a new category
exports.new = (req, res, next) ->
    {conn, r} = req.rethink

    doc =
        id: uuid.v4()
        name: moniker.choose()
        type: Math.ceil(Math.random()*3)
        dataSet: []

    r.table('categories').insert(doc).run conn, (err, results) ->
        res.send doc

exports.create = (req, res, next) ->
exports.show = (req, res, next) ->
exports.update = (req, res, next) ->
exports.destroy = (req, res, next) ->
