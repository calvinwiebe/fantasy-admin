Backbone = require 'backbone'
Backbone.$ = window.$
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
{   contentTemplate
    headerTemplate
    poolTemplate
    actionAreaTemplate
    createFormTemplate } = templates
# views
{GenericView, genericRender} = require 'views'
# models
{PoolModel} = require './models/index.coffee'
# configurations
viewConfig = require './viewConfig.coffee'
views = {}

# --- Three main views: Dashboard, Sidebar, Header ---
# the dashboard contains the sidebar and header. The sidebar
# contains an arbitrary amount of child views. The dashboard also
# contains an action area view. It will be dynamically changed depending
# on what is selected in the sidebar.

# Main Dashboard View.
# It contains:
#
# * `sidebarView`
# * `actionAreaView`
#
exports.DashboardContentView = Backbone.View.extend
    id: 'dashboard'
    template: contentTemplate

    initialize: ->
        # set a default action area
        @eventClasses = viewConfig.actionArea.events
        @actionAreaId = 'dashboard-action-area'
        @actionAreaView = new views[viewConfig.actionArea.default] { @collection }
        @sidebarView = new SidebarView { @collection }
        @headerView = new HeaderView
        @listenTo @sidebarView, 'nav', @onNav

    onNav: (eventData) ->
        actionClass = views[@eventClasses[eventData.type]]
        return false unless actionClass?
        @actionAreaView = new actionClass { @collection }
        @render()

    render: ->
        @$el.empty()
        @$el.append @headerView.render().el
        @$el.append @template()
        @$('#sidebar-content').append @sidebarView.render().el
        @$('#action-area-content').append @actionAreaView.render().el
        this

# Contains controls for navigating the page on the left
# sidebar
#
SidebarView = Backbone.View.extend

    initialize: ->
        @children = []
        @addChildViews()

    # create a bunch of child views based on what is in the
    # config. Pass to each the `pools` model.
    addChildViews: ->
        viewConfig.sidebar.forEach (viewClass) =>
            child = new views[viewClass] {
                @collection
            }
            @children.push child
            @listenTo child, 'nav', (data) -> @trigger 'nav', data

    render: ->
        @$el.empty()
        @children.forEach (child) =>
            @$el.append child.render().el
        this

# The header view
#
HeaderView = Backbone.View.extend
    template: headerTemplate
    id: 'dashboard-header'
    className: 'navbar navbar-inverse navbar-fixed-top'

    render: genericRender

# --- Sidebar dynamic views ---

# Pool List View
#
views.PoolListView = Backbone.View.extend
    template: poolTemplate
    id: 'dashboard-pool-list'

    events:
        'click #new-pool': -> @trigger 'nav', type: 'newPool'

    initialize: ->
        @listenTo @collection, 'add', => @render()

    render: genericRender

# --- Action Area Views ---

# A simple first-login view for dashboard
#
views.DefaultView = Backbone.View.extend
    template: actionAreaTemplate

    render: ->
        @$el.empty()
        @$el.html @template numPools: @collection.models.length
        this

# Form for creating a new pool on the server
#
views.CreatePoolFormView = Backbone.View.extend
    template: createFormTemplate
    id: 'create-pool-form'

    events:
        'click #submit': 'submit'

    initialize: ->
        @model = new PoolModel

    submit: (e) ->
        e.preventDefault()
        @model.set name: @$('#pool-name').val()
        @model.save {},
            success: (model) =>
                @collection.add model
                @$('#pool-name').val ''
                @model = new PoolModel
        false

    render: genericRender

