# {DashboardContentView} = require './content.coffee'
{PoolCollection} = require 'models'

# create a main containing view and insert into it
# a sidebar view, and a action area view.
#
init = (collection) ->
    console.log "received the user's pools"
    console.log collection
    #content = new DashboardContentView { collection }
    #$('body').append content.render().el

$ ->
    pools = new PoolCollection
    pools.fetch success: init
