{DashboardContentView} = require './content.coffee'
Backbone = require 'backbone'
Backbone.$ = window.$

# create a main containing view and insert into it
# a sidebar view, and a action area view.
#
init = (collection) ->
    content = new DashboardContentView { collection }
    $('body').append content.render().el

$ ->
    pools = new Backbone.Collection
    pools.url = '/pools'
    pools.fetch success: init


