Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup} = require 'views'
{PoolListView} = require './views/poolList.coffee'
{PoolHomeView} = require './views/poolHome.coffee'
{PicksView} = require './views/picks.coffee'
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
        'click #home-nav': -> messageBus.put 'nav', page: 'home'
        'click #picks-nav': -> messageBus.put 'nav', page: 'picks'
        'click #standings-nav': -> messageBus.put 'nav', page: 'standings'

    render: ->
        genericRender.call this
        @$el.attr 'role', 'navigation'
        this

# The main manager view.
# This view will swap its content view, while maintaining some basic header/footers. It
# will retain a bunch of app-wide data, and use an event emitter to act on things, rather than
# listening on a bunch of views, since this is the end-all containing view.
#
exports.DashboardContentView = View
    id: 'dashboard'
    className: 'container'
    template: templates.content

    initialize: ({resources}) ->
        _.bindAll this
        @collection  = resources.pools
        @childViews = []
        @state = 'home'
        @listenForEvents()

    listenForEvents: ->
        messageBus \
            .on 'nav', @onNav
            .on 'poolSelected', @poolSelected

    onNav: ({page}) ->
        @state = page
        @render()

    poolSelected: (model) ->
        @state = 'poolHome'
        @selectedPool = model
        @render()

    clearPrevious: ->
        return this unless @firstPoolRender
        @$el.empty()
        this

    renderHeader: ->
        return this unless @firstPoolRender
        @headerView = new HeaderView model: @selectedPool
        $('body').prepend @headerView.render().el
        this

    renderContent: ->
        @contentView.remove()
        switch @state
            when 'poolHome'
                @contentView = new PoolHomeView model: @selectedPool
            when 'picks'
                @contentView = new PicksView model: @selectedPool
        @$el.append @contentView.render().el
        this

    renderHome: ->
        @firstPoolRender = true
        @headerView?.remove()
        @contentView?.remove()
        @contentView = new PoolListView { @collection }
        @childViews.push @contentView
        @$el.append @contentView.render().el

    render: ->
        @undelegateEvents()
        # render the pool list page with no nav header
        if @state is 'home'
            @renderHome()
        # render the header and content view(s)
        else
            # render header view and content view
            @clearPrevious()
            @renderHeader()
            @renderContent()
            @firstPoolRender = false
        @delegateEvents()
        this

