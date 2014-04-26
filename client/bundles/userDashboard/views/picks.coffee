Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder '../templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender,
Cleanup, ListItem, InputListItem,
CategoryInput, IdicatingListItem, TableView} \
= require 'views'
# utils
utils = require 'utils'
# models
{PoolModel, SeriesCollection,
PicksCollection, ModelStorage,
CategoriesCollection, RoundsCollection,
PendingPickModel, PendingPicksUrl} \
= require 'models'
View = Backbone.View.extend.bind Backbone.View

exports.PicksView = View
    template: templates.picks

    initialize: ->
        @needsData = true
        @state = 'list'
        @picks = {}
        $.get PendingPicksUrl, { pool: @model.id }, (data) =>
            ModelStorage.store 'picks', @picks
            @userPending = new PendingPickModel data
            if @userPending.needsPick()
                ModelStorage.getResource "rounds-#{@model.id}", 'pool', @model.id, RoundsCollection, (@rounds) =>
                    round = @rounds.get @userPending.get('round')
                    if moment().isBefore round.get('date')
                        ModelStorage.getResource "categories-#{@model.id}", 'pool', @model.id, CategoriesCollection, (@categories) =>
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

    confirm: ->
        @selectedSeries = null
        @state = 'confirm'
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
            error: (jqxhr) ->
                alert jqxhr.responseJSON?.error or 'error saving'

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
                view = new SeriesList { collection: @series, pool: @model }
                @listenTo view, 'selected', @seriesSelected
                @listenTo view, 'confirm', @confirm
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
            when 'confirm'
                view = new PickConfirmView {
                    series: @series,
                    picks: @picks
                    categories: @categories
                }
                @listenTo view, 'done', @pickSelectionDone
                @listenTo view, 'submit', @submit
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

PickConfirmView = View
    template: templates.confirm

    events:
        'click .back': 'back'
        'click .submit': 'submit'

    initialize: ({@series, @picks, @categories}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @render()

    submit: (e) ->
        e.preventDefault()
        @trigger 'submit'
        false

    back: (e) ->
        e.preventDefault()
        @trigger 'done'
        false

    render: ->
        @undelegateEvents()
        @$el.empty()
        @cleanUp()

        @$el.append @template

        results = _.chain(@picks).values().map((collection) -> collection.models).flatten().map((pick) -> pick.toJSON()).value()
        populatedResults = ModelStorage.populate results, @series
        populatedResults = ModelStorage.populate populatedResults, @categories
        populatedResults = ModelStorage.populate populatedResults, ModelStorage.get 'teams'
        picksTable = new TableView
            headings: @categories.toJSON()
            results: populatedResults
            resultHeadingKey: 'category'
            groupBy: 'series'
        @childViews.push picksTable
        @$('.summary').append picksTable.render().el
        @delegateEvents()
        this


PickInputView = View
    template: templates.input

    events:
        'click .back': 'back'
        'click .save': 'save'

    initialize: ({@pool, @series, @round, @picks, @categories}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @needsData = false
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
    name: "(#{populatedModel.team1?.seed}) #{populatedModel.team1?.shortName} vs (#{populatedModel.team2?.seed}) #{populatedModel.team2?.shortName}"

SeriesList = View
    id: 'series-list'
    template: templates.seriesList

    events:
        'click .submit': 'confirm'

    confirm: (e) ->
        e.preventDefault()
        if @arePicksComplete()
            @trigger 'confirm'
        else
            alert 'Please fill in all your picks first.'
        false

    initialize: ({@pool}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @categories = ModelStorage.get "categories-#{@pool.id}"
        @picks = ModelStorage.get 'picks'

    getPickStatus: (id) ->
        pick = @picks?[id]
        return null unless pick? and @categories
        picksMade = _.chain(pick.pluck('value'))
            .map((value) ->
                return null if _.isEmpty value
                if _.isArray value
                    answer = _.any value, _.isEmpty
                    return null if answer
                true
            ).compact().value()

        if picksMade.length is 0
            null
        else if picksMade.length < @categories.length
            'partial'
        else if picksMade.length is @categories.length
            'full'
        else
            # this shouldn't happen
            null

    arePicksComplete: ->
        complete = _.chain(@collection.toJSON())
            .map((model) =>
                status: @getPickStatus model.id
            ).every(status: 'full')
            .value()

    renderPools: ->
        @childViews = _.chain(@collection.models)
            .map((model) =>
                indicator = @getPickStatus model.id
                map =
                    partial:
                        icon: 'glyphicon-exclamation-sign'
                        class: 'list-group-item-warning'
                    full:
                        icon: 'glyphicon-ok-sign'
                        class: 'list-group-item-success'
                view = new IdicatingListItem {
                    serialize: serializeSeries
                    model
                    icon: map[indicator]?.icon
                    class: map[indicator]?.class
                }
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
