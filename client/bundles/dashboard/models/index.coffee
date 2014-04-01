# Backbone models for the dashboard
#
Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'

Model = Backbone.Model.extend.bind Backbone.Model
Collection = Backbone.Collection.extend.bind Backbone.Collection
syncWithId = (id) ->
    (method, collection, options) ->
        data = {}
        data[id] = this[id]
        Backbone.sync.call this, method, collection, _.extend options, { data }

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
    sync: syncWithId 'pool'

exports.CategoriesCollection = Collection
    url: '/categories'

exports.RoundsCollection = Collection
    url: '/rounds'
    comparator: 'order'
    initialize: ({@pool}) ->
    sync: syncWithId 'pool'

exports.SeriesCollection = Collection
    url: '/series'
    initialize: ({@round}) ->
    sync: syncWithId 'round'

exports.TeamsCollection = Collection
    url: '/teams'
    initialize: ({@league}) ->
    sync: syncWithId 'league'
