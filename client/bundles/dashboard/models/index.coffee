# Backbone models for the dashboard
#
Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'

exports.PoolModel = PoolModel = Backbone.Model.extend
    urlRoot: '/pools'

exports.PoolCollection = Backbone.Collection.extend
    url: '/pools'
    model: PoolModel

exports.UserModel = UserModel = Backbone.Model.extend
    urlRoot: '/users'

exports.UserCollection = Backbone.Collection.extend
    url: '/users'
    model: UserModel

    initialize: ({@pool}) ->

    sync: (method, collection, options) ->
        Backbone.sync.call this, method, collection, _.extend options, data: { @pool }