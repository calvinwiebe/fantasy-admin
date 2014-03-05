Backbone = require 'backbone'
Backbone.$ = window.$

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


