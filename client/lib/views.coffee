Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'

exports.genericRender = genericRender = ->
    @undelegateEvents()
    @$el.empty()
    if @collection?
        data = models: @collection.toJSON()
    else if @model?
        data = @model.toJSON()
    else
        data = {}
    @$el.html @template data
    @delegateEvents()
    this

exports.GenericView = Backbone.View.extend
    initialize: ({@template}) ->
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
