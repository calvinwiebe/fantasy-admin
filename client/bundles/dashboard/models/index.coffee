# Backbone models for the dashboard
#
Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'

Model = Backbone.Model.extend.bind Backbone.Model
Collection = Backbone.Collection.extend.bind Backbone.Collection

exports.GenericModel = GenericModel = Model
    url: '/generic'

exports.PoolModel = PoolModel = Model
    urlRoot: '/pools'

exports.PoolCollection = Collection
    url: '/pools'
    model: PoolModel

exports.UserModel = UserModel = Model
    urlRoot: '/users'

exports.UserCollection = Collection
    url: '/users'
    model: UserModel

    initialize: ({@pool}) ->

    sync: (method, collection, options) ->
        Backbone.sync.call this, method, collection, _.extend options, data: { @pool }

exports.CategoriesCollection = Collection
    url: '/categories'

exports.RoundsCollection = Collection
    url: '/rounds'
    comparator: 'order'

    initialize: ({@pool}) ->

    sync: (method, collection, options) ->
        Backbone.sync.call this, method, collection, _.extend options, data: { @pool }