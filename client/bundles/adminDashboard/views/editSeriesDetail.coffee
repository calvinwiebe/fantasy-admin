Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
templates   = rfolder '../templates', extensions: [ '.jade' ]
{GenericView, genericRender, Cleanup, Swapper, InputListItem} = require 'views'
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

exports.EditSingleSeriesDetail = View
    template: templates.editSeriesDetail

    events:
        'click .save': 'save'

    initialize: ({@context})->
        _.extend this, Cleanup.mixin
        @childViews = []
        {@pool, @series, @teams, @round} = @context
        @needsData = true
        ModelStorage.getResource "categories-#{@pool.id}", 'pool', @pool.id, CategoriesCollection, (@categories) =>
            ModelStorage.getResource "results-#{@series.id}", 'series', @series.id, ResultsCollection, (@previous) =>
                @previous = _.groupBy ModelStorage.populate(@previous, @categories), 'game'
                @results = new ResultsCollection
                @populateResults()
                @needsData = false
                @render()

    populateResults: ->
        _.chain(@categories.models)
            .filter((model) -> model.get('domain') is domainMap['game'])
            .forEach((model) =>
                @results.add
                    series: @series.id
                    round: @round.id
                    category: model.id
                    categoryObject: model.toJSON()
                    game: if (game = _.max(@previous, 'game')) is -Infinity then 1 else game + 1
                    value: null
            )

    save: (e) ->
        e.preventDefault()
        asink.each @results.models, (model, cb) ->
            model.save {}, success: => cb
        , (err) -> alert 'Results saved.'
        false

    renderResults: ->
        console.log @previous
        previousViews = _.chain(@previous)
            .map((collection) =>
                collection.map (model) ->
                    view = new GenericView
                        template: templates.previousResult
                        model:
                            toJSON: -> model
            )
            .flatten()
            .value()

        currentViews = _.chain(@results.models)
            .map((model) =>
                view = new InputListItem { serialize: serializeResult, model }
            ).forEach((view) =>
                @$('form').append view.render().el
            ).value()

        @childViews = _.union previousViews, currentViews
        @childViews.forEach (view) =>
            @$el.append view.render().el
        this

    serialize: ->
        populatedSeries = ModelStorage.populate @series, @teams
        pool: @pool.get 'name'
        series: "#{populatedSeries.team1?.name} vs #{populatedSeries.team2?.name}"

    render: ->
        return this if @needsData
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        @$el.append @template @serialize()
        @renderResults()
        @delegateEvents()
        this
