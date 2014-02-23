template = require './dashboardTemplate.jade'
{GenericView} = require 'views'
Backbone = require 'backbone'
Backbone.$ = window.$

init = (model) ->
    view = new GenericView { template, model }
    $('.content').append view.render().el

$ ->
    pools = new Backbone.Model
    pools.url = '/pools'
    pools.fetch success: init


