{DashboardContentView} = require './content.coffee'
Backbone = require 'backbone'
Backbone.$ = window.$
{PoolCollection} = require './models/index.coffee'

# create a main containing view and insert into it
# a sidebar view, and a action area view.
#
init = (collection) ->
    content = new DashboardContentView { collection }
    $('body').append content.render().el

$ ->
    pools = new PoolCollection
    pools.fetch success: init


