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

exports.InputListItem = Backbone.View.extend
    className: 'input-group'
    template: inputListItem

    initialize: ({@serialize}) ->

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
