Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup, Swapper} = require 'views'
{PoolListView} = require './views/poolList.coffee'
{PicksView} = require './views/picks.coffee'
{StandingsView} = require './views/standings.coffee'
# utils
utils = require 'utils'
# models
{PoolModel} = require 'models'
View = Backbone.View.extend.bind Backbone.View

# TODO: Right now in the admin dash and here we are mixing patterns for handling view changes
# 1. messageBus
# 2. listenTo'ing our childViews.
# Both kind make sense in different situations. We need to start using them for their appropriate
# uses. Can do that after we hack this shit together though.
messageBus = require('events').Bus

HeaderView = View
    tagName: 'nav'
    className: 'navbar navbar-default navbar-static-top'
    template: templates.header

    events:
        'click #home-nav': -> @onNav 'home'
        'click #picks-nav': -> @onNav 'picks'
        'click #standings-nav': -> @onNav 'standings'

    initialize: ->
        _.bindAll this

    onNav: (state) ->
        @trigger 'nav', { state }
        @$('.collapse').collapse('hide')

    render: ->
        genericRender.call this
        @$el.attr 'role', 'navigation'
        this

# The main manager view.
# This view will swap its content view, while maintaining some basic header/footers. It
# will retain a bunch of app-wide data, and use an event emitter to act on things, rather than
# listening on a bunch of views, since this is the end-all containing view.
#
exports.DashboardContentView = Swapper
    id: 'dashboard'
    className: 'container'
    template: templates.content

    initialize: ({resources}) ->
        _.bindAll this
        @collection  = resources.pools
        @childViews = []
        header = {
            root: 'body'
            view: HeaderView
            method: 'prepend'
        }
        @configureSwap
            event: 'nav'
            default: 'home'
            map:
                'standings': [
                    header
                    StandingsView
                ]
                'picks': [
                    header
                    PicksView
                ]
                'home': [
                    PoolListView
                ]

    onNav: ({page}) ->
        @state = page
        @render()

    poolSelected: (model) ->
        @model = model
        @trigger 'nav', state: 'standings'

    afterRender: ->
        if @state is 'home'
            @listenTo @views[0], 'poolSelected', @poolSelected
