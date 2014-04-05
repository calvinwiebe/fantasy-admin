{DashboardContentView} = require './content.coffee'
{PoolCollection, TeamsCollection, UserCollection, ModelStorage} = require 'models'
asink = require 'asink'

# create a main containing view and insert into it
# a sidebar view, and a action area view.
#
init = (resources) ->
    content = new DashboardContentView { resources }
    ModelStorage.store 'teams', resources.teams
    $('body').append content.render().el

$ ->
    # load up for resources at the start
    resources = {
        pools: new PoolCollection
        teams: new TeamsCollection league: 'nhl'
    }
    asink.each resources,
        (collection, cb) ->
            collection.fetch success: (model) -> cb null, model
        , (err) ->
            console.warn? 'Problem loading initial resources' if err?
            init resources

