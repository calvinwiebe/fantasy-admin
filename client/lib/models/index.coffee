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
    initialize: ({@pool}={}) ->
    sync: syncWithId 'pool'

exports.RoundsCollection = Collection
    url: '/rounds'
    comparator: 'order'
    stateMap:
        0: 'disabled'
        1: 'unconfigured'
        2: 'configured'
        3: 'running'
        4: 'finished'

    initialize: ({@pool}={}) ->

    # compute whether a round is needing/ready to accept picks
    #
    anyNeedPicks: ->
        now = Date.now()
        needsPick = false
        @forEach (round) =>
            if @stateMap[round.get('state')] is 'running' \
               and round.get('date') > now
                needsPick = round

        return needsPick

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

exports.PickModel = PickModel = Model
    urlRoot: '/picks'

    toJSON: ->
        attributes = Backbone.Model.prototype.toJSON.call this
        delete attributes.categoryObject
        attributes

exports.PicksCollection = PicksCollection = Collection
    url: '/picks'
    model: PickModel

    save: (options={}) ->
        xhr = @sync 'create', this, {}
        xhr.always options.success

PicksCollection.url = '/picks'


