Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup, Swapper} = require 'views'
{editPool} = rfolder './views', extensions: [ '.coffee' ]
# utils
utils = require 'utils'
# models
{PoolModel, UserCollection, UserModel} = require 'models'
# configurations
viewConfig = require './viewConfig.coffee'
views = {}
views = _.extend views, editPool
View = Backbone.View.extend.bind Backbone.View

# --- Three main views: Dashboard, Sidebar, Header ---
# the dashboard contains the sidebar and header. The sidebar
# contains an arbitrary amount of child views. The dashboard also
# contains an action area view. It will be dynamically changed depending
# on what is selected in the sidebar.

# TODO: Be smarter about rendering. Only re-render what is necessary for the event
# that occurs.

# TODO: don't mix ids of views in jade and in the backbone views. We should put
# all the ids/classes/tagNames of an `entity` into the views, for consistency.

# Main Dashboard View.
# It contains:
#
# * `sidebarView`
# * `actionAreaView`
#
exports.DashboardContentView = Swapper
    id: 'dashboard'
    template: templates.contentTemplate

    initialize: ->
        # set a default action area
        @sidebarEventClasses = viewConfig.sidebar.events
        @sidebarView = new SidebarView { @collection }
        @headerView = new HeaderView
        @firstRender = true
        @configureSwap
            event: 'action'
            default: 'home'
            map:
                'home':
                    views: [ {
                        root: '#action-area-content'
                        view: DefaultView
                    } ]
                'create':
                    views: [ {
                        root: '#action-area-content'
                        view: CreatePoolFormView
                    } ]
                'edit':
                    views: [ {
                        root: '#action-area-content'
                        view: editPool.EditPoolFormView
                    } ]
                # 'editSeries':
                #     views: [ {
                #         root: '#action-area-content'
                #         EditSeriesFormView
                #     } ]

    onNav: ({state, context}) ->
        @trigger 'action', { state, context }

    afterRender: ->
        @listenTo @sidebarView, 'nav', @onNav
        @listenTo @headerView, 'nav', @onNav
        return this if not @firstRender
        @$el.prepend @headerView.render().el
        @$('#sidebar-content').append @sidebarView.render().el
        @firstRender = false

# Contains controls for navigating the page on the left
# sidebar
#
SidebarView = View

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
            @listenTo child, 'nav', (data) => @trigger 'nav', data

    render: ->
        @$el.empty()
        @children.forEach (child) =>
            @$el.append child.render().el
        this

# The header view
#
HeaderView = View
    template: templates.headerTemplate
    id: 'dashboard-header'
    className: 'navbar navbar-inverse navbar-fixed-top'

    events:
        'click .navbar-brand': -> @trigger 'nav', state: 'home'

    render: genericRender

# --- Sidebar dynamic views ---

# Pool List View
#
views.PoolListView = View
    template: templates.poolTemplate
    id: 'dashboard-pool-list'

    events:
        'click #new-pool': -> @trigger 'nav', state: 'create'

    initialize: ->
        _.extend this, Cleanup.mixin
        @listenTo @collection, 'add', => @render()
        @childViews = []

    poolSelected: ({model, event}) ->
        @trigger 'nav', {
            state: 'edit'
            context: {
                model
            }
        }

    render: ->
        genericRender.call this
        @cleanUp()
        @collection.forEach (model) =>
            child = new PoolListItemView { model }
            @childViews.push child
            @$('#pools').prepend child.render().el
            @listenTo child, 'click', @poolSelected
        this


# Pool List Item
# Contains a view of a pool with its own pool model
#
PoolListItemView = View
    template: templates.poolListItem
    tagName: 'li'
    class: 'pool-item'

    events:
        'click': (event) -> @trigger 'click', { @model, event }

    render: genericRender


# --- Action Area Views ---

# A simple first-login view for dashboard
#
DefaultView = View
    template: templates.actionAreaTemplate

    render: ->
        @$el.empty()
        @$el.html @template numPools: @collection.models.length
        this

# A generic message view to indicate something to the user
#
MessageView = View
    template: templates.genericMsgTemplate
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
CreatePoolFormView = View
    template: templates.createPoolFormTemplate
    id: 'create-pool-form'

    events:
        'click #submit' : 'submit'
        'submit form'   : 'submit'

    initialize: ->
        @model = new PoolModel
        @needsData = true
        utils.get resource: 'poolTypes', (types) =>
            @needsData = false
            @types = types
            @render()

    submit: (e) ->
        e.preventDefault()
        @model.set name: @$('#pool-name').val()
        @model.set type: @$('#pool-type').val()
        @model.save {},
            success: (model) =>
                @collection.add model
                @trigger 'action', {
                    state: 'edit'
                    context: {
                        model
                    }
                }
            error: ->
                # TODO show err msg
        false

    renderSelect: ->
        select = @$('#pool-type')
        @types.forEach (type) ->
            # TODO turn into on the fly generic views
            select.append($('<option>').val(type.id).html(type.name))
        @$('#pool-name').focus()

    render: ->
        return this if @needsData
        genericRender.call this
        @renderSelect()
        this
