Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
templates   = rfolder '../templates', extensions: [ '.jade' ]
{GenericView, genericRender, Cleanup, Swapper, InputListItem, ResultTableView} = require 'views'
utils = require 'utils'
{CategoriesCollection, ResultsCollection, ModelStorage} = require 'models'
View = Backbone.View.extend.bind Backbone.View
{EventEmitter} = require 'events'
localBus = new EventEmitter
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

computeState = ->
    switch @series.get 'state'
        when 0
            @state = 'active'
            @domain = 'game'
        when 1
            @state = 'ended'
            @domain = null

# Can be in 3 states:
#
# 1. Active - can input game results
# 2. Ending - can enter series results
# 3. Ended - cannot enter anything
CurrentResult = View
    template: templates.currentResults

    events:
        'click .save'   : 'save'
        'click .ending' : 'ending'
        'click .end'    : 'end'

    initialize: ({@parent}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        {@results, @pool, @series, @round} = @parent
        @needsData = true
        ModelStorage.getResource "categories-#{@pool.id}", 'pool', @pool.id, CategoriesCollection, (@categories) =>
            ModelStorage.getResource "results-#{@series.id}", 'series', @series.id, ResultsCollection, (@previous) =>
                computeState.call this
                @resetResults() unless @state is 'ended'
                @needsData = false
                @render()

    save: (e) ->
        e.preventDefault()
        asink.each @results.models, (model, cb) =>
            model.save {},
                success: (model) =>
                    localBus.put 'new', model
                    cb()
                error: (err, res, options) -> alert 'error saving.'
        , (err) =>
            model = @results.models[0]
            @resetResults model
            @render()
        false

    ending: (e) ->
        e.preventDefault()
        @state = 'ending'
        @domain = 'series'
        @resetResults()
        @render()
        false

    end: (e) ->
        e.preventDefault()
        @state = 'ended'
        asink.each @results.models, (model, cb) ->
            model.save {},
                success: -> cb()
                error: (err, res, options) -> alert 'error saving.'
        , (err) =>
            @series.save state: 1,
                success: =>
                    alert 'series ended.'
                    @render()
        false

    resetResults: (model)->
        @results.set []
        maxGameModel = \
            model ? @previous.max((p) -> p.get('game'))

        _.chain(@categories.models)
            .filter((model) => model.get('domain') is domainMap[@domain])
            .forEach((model) =>
                result =
                    series: @series.id
                    round: @round.id
                    category: model.id
                    categoryObject: model.toJSON()
                    value: null
                if @state is 'active'
                    result.game = if maxGameModel is -Infinity then 1 else maxGameModel.get('game') + 1
                else if @state is 'ending'
                    result.final = '*'
                @results.add result
            )

    renderResults: ->
        @childViews = _.chain(@results.models)
            .map((model) =>
                view = new InputListItem { serialize: serializeResult, model }
            ).forEach((view) =>
                @$('form').append view.render().el
            ).value()
        console.log @childViews
        this

    render: ->
        return this if @needsData
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        @$el.append @template { @state }
        @renderResults() unless @state is 'ended'
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
                localBus.on 'new', (model) =>
                    @previous.add model
                    @render()
                computeState.call this
                @needsData = false
                @render()

    renderPrevious: ->
        gameResults = new ResultTableView
            headings: _.filter @categories.toJSON(), (model) -> model.domain is domainMap['game']
            results: _.filter @previous.toJSON(), (model) -> model.game?
            resultHeadingKey: 'category'
            groupBy: 'game'

        @$el.append gameResults.render().el

        return unless @state is 'ended'
        seriesResults = new ResultTableView
            headings: _.filter @categories.toJSON(), (model) -> model.domain is domainMap['series']
            results: _.filter @previous.toJSON(), (model) -> model.final?
            resultHeadingKey: 'category'
            groupBy: 'final'

        @$el.append seriesResults.render().el

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
