
exports.index = (req, res, next) ->
    res.render 'landing'

exports.auth = require './auth'
exports.dashboard = require './dashboard'