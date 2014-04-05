Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder '../templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup, ListItem} = require 'views'
# utils
utils = require 'utils'
# models
{PoolModel, SeriesCollection, ModelStorage} = require 'models'
View = Backbone.View.extend.bind Backbone.View

messageBus = require('events').Bus

exports.PicksView = View
    template: templates.picks

    initialize: ->
        @needsData = true
        # TODO: get real thing
        @model.set 'roundNeedingPicks', '4575222e-d8a5-42b9-a110-3a1b4d0f30e2'
        @collection = new SeriesCollection round: @model.get 'roundNeedingPicks'
        @collection.fetch success: =>
            @needsData = false
            @render()

    render: ->
        return this if @needsData
        @$el.empty()
        @$el.append @template()
        @$el.append new SeriesList({ @collection }).render().el
        this

serializeSeries = (model) ->
    populatedModel = ModelStorage.populate model, ModelStorage.get 'teams'
    name: "#{populatedModel.team1?.name} vs #{populatedModel.team2?.name}"

SeriesList = View
    id: 'series-list'
    template: templates.seriesList

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []

    renderPools: ->
        @childViews = _.chain(@collection.models)
            .map((model) =>
                view = new ListItem { serialize: serializeSeries, model }
                @listenTo view, 'selected', (model) =>
                    @trigger 'seriesSelected', model
                view
            ).forEach((view) =>
                @$('ul').append view.render().el
            ).value()
        this

    render: ->
        @undelegateEvents()
        @$el.empty()
        @$el.append @template()
        @cleanUp()
        @renderPools()
        @delegateEvents()
        this
