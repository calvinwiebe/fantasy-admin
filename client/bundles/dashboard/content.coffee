Backbone = require 'backbone'
Backbone.$ = window.$
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
{   contentTemplate
    headerTemplate
    poolTemplate
    poolListItem
    actionAreaTemplate
    createFormTemplate
    editFormTemplate
    genericMsgTemplate } = templates
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
        @sidebarEventClasses = viewConfig.sidebar.events
        @messageClasses = viewConfig.actionArea.events
        @actionAreaId = 'dashboard-action-area'
        @actionAreaView = new views[viewConfig.actionArea.default] { @collection }
        @sidebarView = new SidebarView { @collection }
        @headerView = new HeaderView
        @listenTo @sidebarView, 'nav', @onNav
        @listenTo @headerView, 'nav', @onNav

    replaceActionArea: (viewClass, options) ->
        @stopListening @actionAreaView
        @actionAreaView.remove()
        @actionAreaView = new viewClass options
        @listenTo @actionAreaView, 'messageView', @onMessage
        @render()

    onNav: (eventData) ->
        actionClass = views[@sidebarEventClasses[eventData.type]]
        return false unless actionClass?
        @replaceActionArea actionClass, { @collection }

    onMessage: (eventData) ->
        config = @messageClasses[eventData.type]
        return false unless (viewClass = views[config.view])?
        @replaceActionArea viewClass, config.msg

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
        viewConfig.sidebar.views.forEach (viewClass) =>
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

    events:
        'click .navbar-brand': -> @trigger 'nav', type: 'default'

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
        @childViews = []

    # TODO - this stuff will probably become pretty common.
    # Leave for now to keep track of what is going on, but eventually
    # generalize, or use a library.
    cleanUp: ->
        @childViews.forEach (child) =>
            @stopListening child
            child.remove()
        @childViews.length = 0

    remove: ->
        @cleanUp()

    notifyPoolSelected: (model) ->
        @trigger 'nav', {
            type: 'editPool'
            model
        }

    render: ->
        genericRender.call this
        @cleanUp()
        @collection.forEach (model) =>
            child = new PoolListItemView { model }
            @childViews.push child
            @$('#pools').prepend child.render().el
            @listenTo child, 'click', @notifyPoolSelected
        this


# Pool List Item
# Contains a view of a pool with its own pool model
#
PoolListItemView = Backbone.View.extend
    template: poolListItem
    tagName: 'li'
    class: 'pool-item'

    events:
        'click': -> @trigger 'click', @model

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

# A generic message view to indicate something to the user
#
views.MessageView = Backbone.View.extend
    template: genericMsgTemplate
    id: 'generic-message'

    initialize: ({title, msg}) ->
        @model = new Backbone.Model {
            title
            msg
        }
        this

    render: genericRender

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
                @trigger 'messageView', type: 'successPoolCreate'
            error: ->
                # TODO show err msg
        false

    render: genericRender

# Form for editing an existing pool
#
views.EditPoolFormView = Backbone.View.extend
    template: editFormTemplate
    id: 'edit-pool-form'

    render: genericRender

