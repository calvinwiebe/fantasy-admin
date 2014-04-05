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

exports.ModelStorage = require './storage.coffee'

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
    initialize: ({@pool}={}) ->
    sync: syncWithId 'pool'

exports.CategoriesCollection = Collection
    url: '/categories'

exports.RoundsCollection = Collection
    url: '/rounds'
    comparator: 'order'
    initialize: ({@pool}={}) ->
    sync: syncWithId 'pool'

exports.SeriesModel = SeriesModel = Model
    urlRoot: '/series'

    save: (patch, options) ->
        attributes = @toJSON()
        delete attributes.team1Name
        delete attributes.team2Name
        attributes = _.extend {}, attributes, patch
        Backbone.Model::save.call this, attributes, options

exports.SeriesCollection = Collection
    url: '/series'
    model: SeriesModel
    comparator: 'conference'
    initialize: ({@round}={}) ->
    sync: syncWithId 'round'

exports.TeamsCollection = Collection
    url: '/teams'
    comparator: 'seed'
    initialize: ({@league}={}) ->
    sync: syncWithId 'league'
