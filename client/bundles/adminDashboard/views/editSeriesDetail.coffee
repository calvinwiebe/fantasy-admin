Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
templates   = rfolder '../templates', extensions: [ '.jade' ]
{GenericView, genericRender, Cleanup, Swapper, InputListItem, ResultTableView} = require 'views'
utils = require 'utils'
{CategoriesCollection, ResultsCollection, ModelStorage} = require 'models'
View = Backbone.View.extend.bind Backbone.View

# Edit a single series in detail
#
# 1. Enter the results of games
#
serializeResult = (model) ->
    data =
        name: model.get('categoryObject').name
        value: model.get 'value'

domainMap =
    game: 0
    series: 1

exports.EditSingleSeriesDetail = Swapper
    template: templates.editSeriesDetail

    initialize: ({@context})->
        {@pool, @series, @teams, @round} = @context
        @results = new ResultsCollection
        @configureSwap
            event: 'action:editDetail'
            default: 'only'
            map:
                'only':
                    views: [
                            root: '#current'
                            view: CurrentResult
                            name: 'current'
                        ,
                            root: '#previous'
                            view: PreviousResults
                            name: 'previous'
                    ]

    serialize: ->
        populatedSeries = ModelStorage.populate @series, @teams
        pool: @pool.get 'name'
        series: "#{populatedSeries.team1?.name} vs #{populatedSeries.team2?.name}"

CurrentResult = View
    template: templates.currentResults

    events:
        'click .save': 'save'

    initialize: ({@parent}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        {@results, @pool, @series, @round} = @parent
        @needsData = true
        ModelStorage.getResource "categories-#{@pool.id}", 'pool', @pool.id, CategoriesCollection, (@categories) =>
            ModelStorage.getResource "results-#{@series.id}", 'series', @series.id, ResultsCollection, (@previous) =>
                window.previous = @previous
                @populateResults()
                @needsData = false
                @render()

    save: (e) ->
        e.preventDefault()
        asink.each @results.models, (model, cb) ->
            model.save {},
                success: -> cb()
                error: (err, res, options) -> alert 'error saving.'
        , (err) =>
            model = @results.models[0]
            @results = new ResultsCollection
            @populateResults model
            @render()

        false

    populateResults: (model)->
        maxGameModel = \
            model ? @previous.max((p) -> p.get('game'))

        _.chain(@categories.models)
            .filter((model) -> model.get('domain') is domainMap['game'])
            .forEach((model) =>
                @results.add
                    series: @series.id
                    round: @round.id
                    category: model.id
                    categoryObject: model.toJSON()
                    game: if maxGameModel is -Infinity then 1 else maxGameModel.get('game') + 1
                    value: null
            )

    renderResults: ->
        @childViews = _.chain(@results.models)
            .map((model) =>
                view = new InputListItem { serialize: serializeResult, model }
            ).forEach((view) =>
                @$('form').append view.render().el
            ).value()
        this

    render: ->
        return this if @needsData
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        @$el.append @template()
        @renderResults()
        @delegateEvents()
        this

PreviousResults = View
    template: templates.previousResults
    noTemplate: templates.noPrevious

    initialize: ({@parent}) ->
        {@results, @pool, @series} = @parent
        @needsData = true
        ModelStorage.getResource "categories-#{@pool.id}", 'pool', @pool.id, CategoriesCollection, (@categories) =>
            ModelStorage.getResource "results-#{@series.id}", 'series', @series.id, ResultsCollection, (@previous) =>
                @listenTo @results, 'sync', (model) =>
                    @previous.add model unless @previous.contains model
                    @render()
                @needsData = false
                @render()

    renderPrevious: ->
        r = new ResultTableView
            headings: _.filter @categories.toJSON(), (model) -> model.domain is domainMap['game']
            results: @previous.toJSON()
            resultHeadingKey: 'category'
            groupBy: 'game'

        @$el.append r.render().el

    render: ->
        return this if @needsData
        @undelegateEvents()
        @$el.empty()
        @$el.append @template()
        if @previous.length
            @renderPrevious()
        else
            @$el.append @noTemplate()
        @delegateEvents()
        this
