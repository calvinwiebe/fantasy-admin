Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder '../templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup, ListItem, InputListItem} = require 'views'
# utils
utils = require 'utils'
# models
{PoolModel, SeriesCollection,
PicksCollection, ModelStorage,
CategoriesCollection} \
= require 'models'
View = Backbone.View.extend.bind Backbone.View

messageBus = require('events').Bus

exports.PicksView = View
    template: templates.picks

    initialize: ->
        @needsData = true
        @state = 'list'
        # TODO: get real thing
        @model.set 'roundNeedingPicks', '4575222e-d8a5-42b9-a110-3a1b4d0f30e2'
        @collection = new SeriesCollection round: @model.get 'roundNeedingPicks'
        @picks = new PicksCollection
        @collection.fetch success: =>
            @needsData = false
            @collection.forEach (model) => @picks.add series: model.id
            @render()

    seriesSelected: (model) ->
        @selectedSeries = model
        @state = 'input'
        @render()

    pickSelectionDone: ->
        @selectedSeries = null
        @state = 'list'
        @render()

    renderContent: ->
        if @state is 'list'
            view = new SeriesList { @collection }
            @listenTo view, 'selected', @seriesSelected
        else if @state is 'input'
            pickModel = @picks.find id: @selectedSeries.id
            view = new PickInputView { pool: @model, model: pickModel, series: @selectedSeries }
            @listenTo view, 'done', @pickSelectionDone
        @$el.append view.render().el
        this

    render: ->
        return this if @needsData
        @$el.empty()
        @$el.append @template()
        @renderContent()
        this

PickInputView = View
    template: templates.input

    events:
        'click .done': 'save'

    initialize: ({@pool, @series}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @categories = ModelStorage.get "categories-#{@pool.id}"
        unless @categories
            @needsData = true
            @categories = new CategoriesCollection pool: @pool.id
            @categories.fetch success: =>
                ModelStorage.store "categories-#{@pool.id}", @categories
                @needsData = false
                @render()

    renderCategories: ->
        @childViews = _.chain(@categories.models)
            .map((model) =>
                view = new InputListItem { model }
            ).forEach((view) =>
                @$('form').append view.render().el
            ).value()
        this

    save: (e) ->
        e.preventDefault()
        @trigger 'done'
        false

    render: ->
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        populatedSeries = ModelStorage.populate @series, ModelStorage.get 'teams'
        @$el.append @template populatedSeries
        @renderCategories()
        @delegateEvents()
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
                    @trigger 'selected', model
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
