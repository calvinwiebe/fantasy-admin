template = require './dashboardTemplate.jade'
Backbone = require 'backbone'
$ = require 'jquery'
Backbone.$ = $

exports.DashboardView = Backbone.View.extend

    initialize: ->

    render: ->
        @$el.empty()
        @$el.html template @model.toJSON()
        this
