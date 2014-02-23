Backbone = require 'backbone'
Backbone.$ = window.$

exports.GenericView = Backbone.View.extend

    initialize: ({@template}) ->

    render: ->
        @$el.empty()
        @$el.html @template @model?.toJSON() or {}
        this

