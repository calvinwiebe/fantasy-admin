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
CategoriesCollection, RoundsCollection} \
= require 'models'
View = Backbone.View.extend.bind Backbone.View

messageBus = require('events').Bus

exports.PicksView = View
    template: templates.picks

    initialize: ->
        @needsData = true
        @state = 'list'
        @picks = {}
        ModelStorage.getResource "rounds-#{@model.id}", 'pool', @model.id, RoundsCollection, (@rounds) =>
            if (round = @rounds.anyNeedPicks())
                ModelStorage.getResource "series-#{round.id}", 'round', round.id, SeriesCollection, (@series) =>
                    @series.forEach (model) =>
                        @picks[model.id] = new PicksCollection
                    @needsData = false
                    @render()
            else
                @state = 'none'
                @needsData = false
                @render()

    # Send the picks to the server
    # Boil everything down to one flat picks collection and save it
    #
    submit: ->
        models = _.chain(@picks)
            .values()
            .map((collection) -> collection.models)
            .flatten()
            .value()
        saver = new PicksCollection models
        saver.sync 'create', saver,
            success: -> alert 'Picks saved.'
            error: -> alert 'error saving'

    seriesSelected: (model) ->
        @selectedSeries = model
        @state = 'input'
        @render()

    pickSelectionDone: ->
        @selectedSeries = null
        @state = 'list'
        @render()

    renderContent: ->
        @stopListening()
        if @state is 'list'
            view = new SeriesList { collection: @series }
            @listenTo view, 'selected', @seriesSelected
            @listenTo view, 'submit', @submit
        else if @state is 'input'
            view = new PickInputView {
                pool: @model,
                series: @selectedSeries,
                picks: @picks[@selectedSeries.id]
                round: @rounds.anyNeedPicks()
            }
            @listenTo view, 'done', @pickSelectionDone
        else if @state is 'none'
            view = NoPicksNeeded
        @$('.picks').append view.render().el
        this

    render: ->
        return this if @needsData
        @$el.empty()
        @$el.append @template()
        @renderContent()
        this

serializePick = (model) ->
    data =
        name: model.get('categoryObject').name
        value: model.get 'value'

NoPicksNeeded = new GenericView template: templates.none

PickInputView = View
    template: templates.input

    events:
        'click .done': 'done'

    initialize: ({@pool, @series, @round, @picks}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @needsData = false
        @categories = ModelStorage.get "categories-#{@pool.id}"
        if !@categories
            @needsData = true
            @categories = new CategoriesCollection pool: @pool.id
            @categories.fetch success: =>
                ModelStorage.store "categories-#{@pool.id}", @categories
                @populatePicks()
                @needsData = false
                @render()
        else
            @populatePicks()

    populatePicks: ->
        if @picks.isEmpty()
            @categories.forEach (model) =>
                @picks.add
                    series: @series.id
                    round: @round.id
                    category: model.id
                    categoryObject: model.toJSON()
                    value: null

    renderCategories: ->
        @childViews = _.chain(@picks.models)
            .map((model) =>
                view = new InputListItem { serialize: serializePick, model }
            ).forEach((view) =>
                @$('form').append view.render().el
            ).value()
        @$('input').first().focus()
        this

    done: (e) ->
        e.preventDefault()
        @trigger 'done'
        false

    render: ->
        return this if @needsData
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

    events:
        'click .submit': 'submit'

    submit: (e) ->
        e.preventDefault()
        @trigger 'submit'
        false

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
