Backbone = require 'backbone'
Backbone.$ = window.$

exports.genericRender = genericRender = ->
    @$el.empty()
    @$el.html @template @model?.toJSON() or {}
    this

exports.GenericView = Backbone.View.extend
    initialize: ({@template}) ->
    render: genericRender


