# Commonly Used Generic Views
#
Backbone        = require 'backbone'
Backbone.$      = window.$
_               = require 'lodash'
listItem        = require './listItem.jade'
inputListItem   = require './inputListItem.jade'

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
exports.InputListItem = View
    className: 'form-group'
    template: inputListItem

    events:
        'blur input': 'onBlur'

    initialize: ({@serialize}) ->

    onBlur: ->
        @model.set 'value', @$('input').val()

    render: genericRender