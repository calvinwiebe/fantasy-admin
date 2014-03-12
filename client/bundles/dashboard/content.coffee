Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder './templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup} = require 'views'
# models
{PoolModel, UserCollection, UserModel} = require './models/index.coffee'
# configurations
viewConfig = require './viewConfig.coffee'
views = {}

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
    template: templates.editFormTemplate
    id: 'edit-pool-form'

    events:
        'click #save'    : 'save'

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @participantsView = new ParticipantsView { @model }
        @childViews.push @participantsView

    # retrieve all of our sub collection/models from
    # our childViews, and persist them to the server.
    #
    # participants: if a participant model does not have an id, it is new.
    # In this case we sent it to the server to be created. We should also then
    # resync the pool, as it will have a new user attached to it.
    #
    save: (e) ->
        e.preventDefault()
        shouldSyncPool = false
        participants = @participantsView.getData()
        savePool = =>
            ids = participants.map (p) -> p.get('id')
            @model.set users: ids
            @model.save({}, -> alert('pool saved.'))
        asink.each participants.models,
            (user, cb) =>
                user.set pool: @model.get('id') if user.isNew()
                user.save({}, success: -> cb())
            , (err) -> savePool()
        false

    render: ->
        genericRender.call this
        @cleanUp()
        @$('#participants').append @participantsView.render().el
        this

ParticipantsView = Backbone.View.extend

    events:
        'click #users-list'     : 'showEditUsers'
        'click .glyph'          : 'showUserList'

    initialize: (users=[]) ->
        @isEditing = false
        _.extend this, Cleanup.mixin
        @collection = new UserCollection pool: @model.get('id')
        @collection.fetch success: => @render()
        @childViews = []

    getData: ->
        return @collection

    showEditUsers: ->
        @isEditing = true
        @render()

    showUserList: ->
        users = _.chain(@childViews)
            .map((c) -> c.model)
            .filter((m) -> m?.get('email'))
            .value()
        @collection.set users
        @isEditing = false
        @render()

    newUser: (user) ->
        @render()

    renderCurrentView: ->
        if !@isEditing
            @childViews.push new ParticipantsListView { @collection }
        else
            if @collection.length
                @childViews = @collection.map (user) =>
                    new ParticipantView model: user
            else
                @collection.reset()
            empty = new ParticipantView model: new UserModel {email:''}
            @childViews.push empty
            @childViews.push new GenericView template: templates.glyphOk
        @childViews.forEach (v) =>
            @listenTo v, 'new', @newUser
            @$el.append v.render().el
        if empty?
            empty.$el.find('input').focus()

    render: ->
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        @renderCurrentView()
        @delegateEvents()
        this

ParticipantsListView = Backbone.View.extend
    template: templates.participants_
    render: genericRender

ParticipantView = Backbone.View.extend
    template: templates.participant_

    events:
        'keypress .user-input'  : 'keyPress'
        'blur .user-input'      : 'blur'

    blur: (e) ->
        email = @$('input').val()
        @model.set { email }

    keyPress: (e) ->
        email = @$('input').val()
        return if e.keyCode isnt 13 or _.isEmpty email
        @model.set { email }
        @trigger 'new', @model
        e.preventDefault()
        false

    render: genericRender

