Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder '../templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup, ListItem, InputListItem, CategoryInput} = require 'views'
# utils
utils = require 'utils'
# models
{PoolModel, SeriesCollection,
PicksCollection, ModelStorage,
CategoriesCollection, RoundsCollection,
PendingPickModel, PendingPicksUrl} \
= require 'models'
View = Backbone.View.extend.bind Backbone.View

messageBus = require('events').Bus

exports.PicksView = View
    template: templates.picks

    initialize: ->
        @needsData = true
        @state = 'list'
        @picks = {}
        $.get PendingPicksUrl, { pool: @model.id }, (data) =>
            @userPending = new PendingPickModel data
            if @userPending.needsPick()
                ModelStorage.getResource "rounds-#{@model.id}", 'pool', @model.id, RoundsCollection, (@rounds) =>
                    round = @rounds.get @userPending.get('round')
                    if moment().isBefore round.get('date')
                        ModelStorage.getResource "series-#{round}", 'round', round.id, SeriesCollection, (@series) =>
                            @series.forEach (model) =>
                                @picks[model.id] = new PicksCollection
                                @needsData = false
                                @render()
                    else
                        @state = 'timesup'
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
            success: =>
                @userPending.destroy success: =>
                @trigger 'nav', state: 'standings'
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
        switch @state
            when 'list'
                view = new SeriesList { collection: @series }
                @listenTo view, 'selected', @seriesSelected
                @listenTo view, 'submit', @submit
            when 'input'
                view = new PickInputView {
                    pool: @model,
                    series: @selectedSeries,
                    picks: @picks[@selectedSeries.id]
                    round: @userPending.get('round')
                }
                @listenTo view, 'done', @pickSelectionDone
            when 'none'
                view = NoPicksNeeded
            when 'timesup'
                view = TimesUp
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
TimesUp = new GenericView template: templates.timesup

PickInputView = View
    template: templates.input

    events:
        'click .back': 'back'
        'click .save': 'save'

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
                    round: @round
                    category: model.id
                    categoryObject: model.toJSON()
                    value: null

    renderCategories: (populatedSeries) ->
        @childViews = _.chain(@picks.models)
            .map((model) =>
                view = new CategoryInput { model, populatedSeries}
            ).forEach((view) =>
                @$('form').append view.render().el
            ).value()
        @$('.category-input').first().focus()
        this

    save: (e) ->
        _.each @childViews, (view) =>
            category = @picks.findWhere category: view.model.get('category')
            category.set value: view.getValue()
        @back(e)

    back: (e) ->
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
        @renderCategories populatedSeries
        @delegateEvents()
        this

serializeSeries = (model) ->
    populatedModel = ModelStorage.populate model, ModelStorage.get 'teams'
    name: "(#{populatedModel.team1?.seed}) #{populatedModel.team1?.name} vs (#{populatedModel.team2?.seed}) #{populatedModel.team2?.name}"

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
