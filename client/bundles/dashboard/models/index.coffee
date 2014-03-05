# Backbone models for the dashboard
#
Backbone = require 'backbone'
Backbone.$ = window.$

exports.PoolModel = Backbone.Model.extend
    url: '/pools'

exports.PoolCollection = Backbone.Collection.extend
    url: '/pools'

exports.UserCollection = Backbone.Collection.extend
    url: '/users'

    initialize: (@poolId) ->

    sync: (method, collection, options) ->
        Backbone.sync.call this, data: id: @poolId