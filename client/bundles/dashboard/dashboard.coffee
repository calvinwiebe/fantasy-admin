{DashboardContentView} = require './content.coffee'
Backbone = require 'backbone'
Backbone.$ = window.$

# create a main containing view and insert into it
# a sidebar view, and a action area view.
#
init = (model) ->
    content = new DashboardContentView pools: model
    $('body').append content.render().el

$ ->
    pools = new Backbone.Model
    pools.url = '/pools'
    pools.fetch success: init


