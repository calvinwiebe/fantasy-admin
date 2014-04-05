Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup} = require 'views'
{editPool} = rfolder './views', extensions: [ '.coffee' ]
# utils
utils = require 'utils'
# models
{PoolModel, UserCollection, UserModel} = require 'models'
# configurations
viewConfig = require './viewConfig.coffee'
views = {}
views = _.extend views, editPool

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
exports.DashboardContentView = Backbone.View.extend
    id: 'dashboard'
    template: templates.contentTemplate

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
        model = eventData.model
        collection = if model? then null else @collection
        @replaceActionArea actionClass, { collection, model }

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
    template: templates.headerTemplate
    id: 'dashboard-header'
    className: 'navbar navbar-inverse navbar-fixed-top'

    events:
        'click .navbar-brand': -> @trigger 'nav', type: 'default'

    render: genericRender

# --- Sidebar dynamic views ---

# Pool List View
#
views.PoolListView = Backbone.View.extend
    template: templates.poolTemplate
    id: 'dashboard-pool-list'

    events:
        'click #new-pool': -> @trigger 'nav', type: 'newPool'

    initialize: ->
        _.extend this, Cleanup.mixin
        @listenTo @collection, 'add', => @render()
        @childViews = []

    poolSelected: ({model, event}) ->
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
            @listenTo child, 'click', @poolSelected
        this


# Pool List Item
# Contains a view of a pool with its own pool model
#
PoolListItemView = Backbone.View.extend
    template: templates.poolListItem
    tagName: 'li'
    class: 'pool-item'

    events:
        'click': (event) -> @trigger 'click', { @model, event }

    render: genericRender


# --- Action Area Views ---

# A simple first-login view for dashboard
#
views.DefaultView = Backbone.View.extend
    template: templates.actionAreaTemplate

    render: ->
        @$el.empty()
        @$el.html @template numPools: @collection.models.length
        this

# A generic message view to indicate something to the user
#
views.MessageView = Backbone.View.extend
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
views.CreatePoolFormView = Backbone.View.extend
    template: templates.createFormTemplate
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
                @trigger 'messageView', type: 'successPoolCreate'
            error: ->
                # TODO show err msg
        false

    renderSelect: ->
        select = @$('#pool-type')
        @types.forEach (type) ->
            # TODO turn into on the fly generic views
            select.append($('<option>').val(type.id).html(type.name))

    render: ->
        return this if @needsData
        genericRender.call this
        @renderSelect()
        this
