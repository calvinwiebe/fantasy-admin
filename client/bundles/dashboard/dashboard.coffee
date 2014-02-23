Backbone = require 'backbone'
$ = require 'jquery'
Backbone.$ = $

{DashboardView} = require './dashboardView.coffee'

init = (model) ->
    view = new DashboardView { model }
    $('.content').append view.render().el

$ ->
    pools = new Backbone.Model
    pools.url = '/pools'
    pools.fetch success: init


