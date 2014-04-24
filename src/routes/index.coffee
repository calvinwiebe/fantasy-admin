
exports.index = (req, res, next) ->
    res.render 'landing', app: 'login'

exports.passwordReset = (req, res, next) ->
    res.render 'passwordReset', app: 'passwordReset'

exports.auth = require './auth'
exports.dashboard = require './dashboard'
exports.resources = require './resources'
exports.clientResources = require './clientResources'