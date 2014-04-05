Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
listItem    = require './listItem.jade'
inputListItem    = require './inputListItem.jade'

exports.genericRender = genericRender = ->
    @undelegateEvents()
    @$el.empty()
    if @serialize?
        data = @template @serialize @model
    else if @collection?
        data = @template models: @collection.toJSON()
    else if @model?
        data = @template @model.toJSON()
    else
        data = {}
    @$el.html data
    @delegateEvents()
    this

exports.GenericView = Backbone.View.extend
    initialize: ({@template}) ->
    render: genericRender

# A generic view to show a list item in a list-group
# If it is clicked, it will trigger an event with its model
#
exports.ListItem = Backbone.View.extend
    tagName: 'li'
    className: 'list-group-item'
    template: listItem

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
exports.InputListItem = Backbone.View.extend
    className: 'input-group'
    template: inputListItem

    events:
        'blur': 'onBlur'

    initialize: ({@serialize}) ->

    onBlur: ->
        @model.set 'value', @$('input').val()

    render: genericRender

Cleanup = {}
Cleanup.mixin =
    cleanUp: ->
        @childViews.forEach (child) =>
            @stopListening child
            child.remove()
        @childViews.length = 0

    remove: ->
        @cleanUp()

exports.Cleanup = Cleanup
