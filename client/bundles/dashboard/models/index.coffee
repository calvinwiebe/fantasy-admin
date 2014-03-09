# Backbone models for the dashboard
#
Backbone = require 'backbone'
Backbone.$ = window.$

exports.PoolModel = PoolModel = Backbone.Model.extend
    url: '/pools'

exports.PoolCollection = Backbone.Collection.extend
    url: '/pools'
    model: PoolModel

exports.UserModel = UserModel = Backbone.Model.extend
    url: '/users'

exports.UserCollection = Backbone.Collection.extend
    url: '/users'
    model: UserModel

    initialize: (@poolId) ->

    sync: (method, collection, options) ->
        Backbone.sync.call this, data: id: @poolId