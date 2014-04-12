_ = require 'lodash'
Backbone = require 'backbone'

class ModelStorage
    constructor: ->
        @resources = {}
        @nil = {}

    # Save the model into the storage
    #
    store: (name, model) ->
        @resources[name] = model

    # Get a stored model
    #
    get: (name) ->
        @resources[name]

    # Generic async getResource; either from cache or server.
    #
    getResource: (name, key, val, collectionClass, cb) ->
        resource = @get name
        if resource?
            console.log "got a cached version of a resource #{name}"
            setTimeout ->
                cb resource
            , 0
        else
            options = {}
            options[key] = val
            resource = new collectionClass options
            resource.fetch success: =>
                @store name, resource
                cb resource

    # Test to see if a string is a valid `uuid v4`.
    #
    isId: (attribute) ->
        /[0-9a-f]{22}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i.test attribute

    toArray: (model) ->
        if _.isArray model
            model
        else if model instanceof Backbone.Collection
            array = model.toJSON()
        else if model instanceof Backbone.Model
            array = [ model.toJSON() ]
        else
            [@nil]

    insert: (model, key, {index, val}, populator) ->
        if @isId(val) and val is populator.id
            if index >= 0
                model[key][index] = populator
            else
                model[key] = populator

    # Helper for `populate` to iterate over models
    #
    populateModel: (model, populator) ->
        if populator is @nil
            # search the entire `resource` object
        else
            _.forOwn model, (val, key) =>
                if _.isArray val
                    for i, index in val
                        @insert model, key, { index, val: i } , populator
                else
                    @insert model, key, { val }, populator

    # pass in a Backbone Model or Collection
    # and it will take all the entries that are `ids` and populate
    # them with a full object, if that object exists in `@resources`
    #
    # * `model` - the model to be populated
    # * `populator` - (optional) - if this is present, it will use this referenced object
    # to populate the `model`
    #
    # Assumption: Backbone Models should never have deep objects. It should only have arrays
    # and basic types
    #
    populate: (model, populator) ->
        _model = @toArray model
        _populator = @toArray populator

        for m in _model
            for p in _populator
                @populateModel m, p

        if _model.length is 1 then _model[0] else _model


module.exports = new ModelStorage