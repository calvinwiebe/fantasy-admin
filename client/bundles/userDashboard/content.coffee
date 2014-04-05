Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup} = require 'views'
{PoolListView} = require './views/poolList.coffee'
# utils
utils = require 'utils'
# models
{PoolModel} = require 'models'
View = Backbone.View.extend.bind Backbone.View

messageBus = require('events').Bus

# The main manager view.
# This view will swap its content view, while maintaining some basic header/footers. It
# will retain a bunch of app-wide data, and use an event emitter to act on things, rather than
# listening on a bunch of views, since this is the end-all containing view.
#
exports.DashboardContentView = View
    id: 'dashboard'

    initialize: ->
        @childViews = []
        @state = 'home'
        @listenForEvents()

    listenForEvents: ->
        messageBus \
            .on 'nav', @onNav.bind(this)

    onNav: ({page}) ->
        @state = page
        @render()

    render: ->
        @undelegateEvents()
        # render the pool list page with no nav header
        if @state is 'home'
            @$el.empty()
            @contentView = new PoolListView { @collection }
            @childViews.push @contentView
            @$el.append @contentView.render().el
        # render the header and content view(s)
        else
            # render header view and content view
        @delegateEvents()
        this

HeaderView = View
    id: 'header'
    template: templates.header

    events:
        'click #home-nav': -> messageBus.put 'nav', page: 'home'
        'click #picks-nav': -> messageBus.put 'nav', page: 'picks'
        'click #standings-nav': -> messageBus.put 'nav', page: 'standings'

    render: genericRender
