
exports.index = (req, res, next) ->
    res.render 'landing'

exports.auth = require './auth'