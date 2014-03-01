Backbone = require 'backbone'
Backbone.$ = window.$
# templates
# main
contentTemplate = require './content.jade'
headerTemplate = require './header.jade'
poolTemplate = require './poolList.jade'
defaultActionAreaTemplate = require './actionArea.jade'
# form view
createFormTemplate = require './createPoolForm.jade'
# views
{GenericView, genericRender} = require 'views'

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

    initialize: ({@pools}) ->
        # set a default action area
        @eventClasses = viewConfig.actionArea.events
        @actionAreaId = 'dashboard-action-area'
        @actionAreaView = new views[viewConfig.actionArea.default]
            model: @pools
        @sidebarView = new SidebarView pools: @pools
        @headerView = new HeaderView
        @listenTo @sidebarView, 'nav', @onNav

    onNav: (eventData) ->
        actionClass = views[@eventClasses[eventData.type]]
        return false unless actionClass?
        @actionAreaView = new actionClass
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

    initialize: ({@pools}) ->
        @children = []
        @addChildViews()

    # create a bunch of child views based on what is in the
    # config. Pass to each the `pools` model.
    addChildViews: ->
        viewConfig.sidebar.forEach (viewClass) =>
            child = new views[viewClass] {
                model: @pools
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

    render: genericRender

# --- Action Area Views ---

# A simple first-login view for dashboard
#
views.DefaultView = Backbone.View.extend
    template: defaultActionAreaTemplate

    render: ->
        @$el.empty()
        @$el.html @template numPools: @model.get('pools').length
        this

# Form for creating a new pool on the server
#
views.CreatePoolFormView = Backbone.View.extend
    template: createFormTemplate

    events:
        'click #submit': 'submit'

    submit: (e) ->
        e.preventDefault()
        poolName = @$('#pool-name').val()
        $.post('/pools/', {
            name: poolName
            })
        false

    render: genericRender

