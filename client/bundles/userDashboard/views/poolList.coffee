Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder '../templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup, ListItem} = require 'views'
# utils
utils = require 'utils'
# models
{PoolModel} = require 'models'
View = Backbone.View.extend.bind Backbone.View

messageBus = require('events').Bus

# Shows a list of the pools
#
exports.PoolListView = View
    id: 'pool-list'
    template: templates.poolList

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []

    renderPools: ->
        @childViews = _.chain(@collection.models)
            .map((model) =>
                view = new ListItem { model }
                @listenTo view, 'selected', (model) ->
                    messageBus.put 'poolSelected', model
                view
            ).forEach((view) =>
                @$('ul').append view.render().el
            ).value()
        this

    render: ->
        @undelegateEvents()
        @$el.empty()
        @$el.append @template()
        @cleanUp()
        @renderPools()
        @delegateEvents()
        this
