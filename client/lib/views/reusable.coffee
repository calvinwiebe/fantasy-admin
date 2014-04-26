# Commonly Used Generic Views
#
Backbone        = require 'backbone'
Backbone.$      = window.$
_               = require 'lodash'
templates       = rfolder './templates', extensions: [ '.jade' ]
{Cleanup}       = require './manage.coffee'
{ModelStorage}  = require 'models'

View = Backbone.View.extend.bind Backbone.View

exports.genericRender = genericRender = ->
    @undelegateEvents()
    @$el.empty()
    if @serialize?
        data = @template @serialize @model
    else if @collection? and @model?
        data = @template _.extend @model.toJSON(), models: @collection.toJSON()
    else if @collection?
        data = @template models: @collection.toJSON()
    else if @model?
        data = @template @model.toJSON()
    else
        data = @template {}
    @$el.html data
    @delegateEvents()
    this

exports.GenericView = View
    initialize: ({@template}) ->
    render: genericRender

# A generic view to show a list item in a list-group
# If it is clicked, it will trigger an event with its model
#
exports.ListItem = View
    tagName: 'li'
    className: 'list-group-item'
    template: templates.listItem

    events:
        'click': 'onClick'

    initialize: ({@serialize}) ->

    onClick: ->
        @trigger 'selected', @model

    render: genericRender

exports.IdicatingListItem = View
    tagName: 'li'
    className: 'list-group-item'
    template: templates.indicatingListItem

    events:
        'click': 'onClick'

    initialize: ({@serialize, @icon, @class}) ->
        @serialize = _.compose @_serialize, @serialize

    onClick: ->
        @trigger 'selected', @model

    _serialize: (data) ->
        _.extend data, {@icon}

    render: ->
        genericRender.call this
        return this unless @class
        @$el.addClass @class
        this


# A generic view to show a bunch of input items, with a model attached
# to them. When the view is blurred, it will set the value of the single input
# on the model's `value` attr
#
exports.InputListItem = View
    className: 'form-group'
    template: templates.inputListItem

    events:
        'blur input': 'onBlur'

    initialize: ({@serialize}) ->

    onBlur: ->
        @model.set 'value', @$('input').val()

    render: genericRender


exports.CategoryInput = View
    template: templates.categoryInput

    initialize: ({ @model, @populatedSeries }) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @render()

    render: ->
        @$el.empty()
        @cleanUp()
        categoryObject = @model.get('categoryObject')
        args =
            id: categoryObject.id
            type: categoryObject.type
            value: @model.get 'value'
            name: categoryObject.name
        switch categoryObject.type
            when 0
                switch categoryObject.enumType
                    when 0
                        args.data = _.map [@populatedSeries.team1, @populatedSeries.team2], (team) ->
                             value: team.id, label: team.name
                    when 1
                        args.data = _.map _.sortBy(@populatedSeries.team1.players, (player) -> -player.gReg), (player) ->
                            value: player.name, label: '(' + player.position + ') ' + player.name  + ' - ' + player.gReg + ' goals'
                    when 2
                        args.data = _.map _.sortBy(@populatedSeries.team2.players, (player) -> -player.gReg), (player) ->
                            value: player.name, label: '(' + player.position + ') ' + player.name  + ' - ' + player.gReg + ' goals'

        @$el.append @template args
        this

    getValue: ->
        inputs = @$('.category-input')
        if inputs.length is 1 then inputs.val()
        else _.map inputs, (input) -> $(input).val()

# A row in a table
#
TableRow = View
    tagName: 'tr'

    initialize: ({@tagType, @value, @pluck}) ->
        @template = if @tagType is 'td' then templates.td else templates.th

    deepFind: (object, prop) ->
        return object[prop] if object[prop]?
        for key, val of object
            if val[prop]?
                return val[prop]
            else if _.isObject val
                @deepFind val
        return null

    getValue: (value) ->
        if _.isArray value
            value = _.reduce(value, (memo, v) =>
                memo + '-' + @getValue(v)
            )
        else if @pluck and _.isObject value
            value = @deepFind value, @pluck
        value

    renderChildren: ->
        _.forEach @collection, (rowData) =>
            value = rowData[@value]
            value = @getValue value
            @$el.append @template { value }

    render: ->
        @$el.empty()
        @renderChildren()
        this

# A reusable TableView
# This takes a collection of headings, and a collection of result collections.
#
exports.TableView = View
    template: templates.table

    initialize: ({@headings, @results, @resultHeadingKey, @groupBy}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @headings = _.sortBy @headings, 'id'
        @headings.unshift name: @groupBy.toUpperCase()
        # if groupBy is on an expanded object, group by its id
        @results = _.groupBy @results, (data) => 
            if _.isObject(data) and data[@groupBy].id
                data[@groupBy].name
            else
                data[@groupBy]
        rowKeys = _.keys @results
        # if groupBy is on an expanded object, sort by its id
        @results = _.map @results, (collection) => 
            _.sortBy collection, (data) =>
                if _.isObject(data) and data[@resultHeadingKey].id
                    data[@resultHeadingKey].id
                else
                    data[@resultHeadingKey]
        @results.forEach (collection, i) ->
            collection.unshift value: rowKeys[i]

    renderRows: ->
        heading = new TableRow
            collection: @headings
            tagType: 'th'
            value: 'name'
        @$('thead').append heading.render().el

        rows = _.chain(@results)
            .map((collection) =>
                new TableRow
                    collection: collection
                    tagType: 'tr'
                    value: 'value'
                    pluck: 'name'
            ).forEach((view) =>
                @$('tbody').append view.render().el
            )

        @childViews = _.union heading, rows

    render: ->
        @cleanUp()
        @$el.empty()
        @$el.html @template()
        @renderRows()
        this



