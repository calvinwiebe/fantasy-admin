# Commonly Used Generic Views
#
Backbone        = require 'backbone'
Backbone.$      = window.$
_               = require 'lodash'
templates       = rfolder './templates', extensions: [ '.jade' ]
{Cleanup}       = require './manage.coffee'

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

# A row in a table
#
ResultTableRow = View
    tagName: 'tr'

    initialize: ({@tagType, @value}) ->
        @template = if @tagType is 'td' then templates.td else templates.th

    renderChildren: ->
        _.forEach @collection, (rowData) =>
            @$el.append @template
                value: rowData[@value]

    render: ->
        @$el.empty()
        @renderChildren()
        this

# A reusable TableView
# This takes a collection of headings, and a collection of result collections.
#
exports.ResultTableView = View
    template: templates.table

    initialize: ({@headings, @results, @resultHeadingKey, @groupBy}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @headings = _.sortBy @headings, 'id'
        @headings.unshift name: @groupBy.toUpperCase()
        @results = _.groupBy @results, @groupBy
        rowKeys = _.keys @results
        @results = _.map @results, (collection) => _.sortBy collection, "#{@resultHeadingKey}"
        @results.forEach (collection, i) ->
            collection.unshift value: rowKeys[i]

    renderRows: ->
        heading = new ResultTableRow
            collection: @headings
            tagType: 'th'
            value: 'name'
        @$('thead').append heading.render().el

        rows = _.chain(@results)
            .map((collection) =>
                new ResultTableRow
                    collection: collection
                    tagType: 'tr'
                    value: 'value'
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


