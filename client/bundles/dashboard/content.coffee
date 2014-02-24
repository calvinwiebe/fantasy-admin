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
{GenericView} = require 'views'

# Main Dashboard View.
# It contains:
#
# * `sidebarView`
# * `actionAreaView`
#
exports.DashboardContentView = Backbone.View.extend
    id: 'dashboard'

    initialize: ({@pools}) ->
        # set a default action area
        @actionAreaId = 'dashboard-action-area'
        @actionAreaView = new DefaultView
            model: @pools
        @sidebarView = new SidebarView pools: @pools
        @listenTo @sidebarView, 'nav', @onNav

    onNav: (eventData) ->
        if eventData.type is 'newPool'
            @actionAreaView = new CreatePoolFormView
        @render()

    render: ->
        @headerView = new GenericView {
            template: headerTemplate
            id: 'dashboard-header'
            className: 'navbar navbar-inverse navbar-fixed-top'
        }
        @$el.empty()
        @$el.append @headerView.render().el
        @$el.append contentTemplate()
        @$('#sidebar-content').append @sidebarView.render().el
        @$('#action-area-content').append @actionAreaView.render().el
        this

# A simple first-login view for dashboard
#
DefaultView = Backbone.View.extend

    initialize: ->
        @template = defaultActionAreaTemplate

    render: ->
        @$el.empty()
        @$el.html @template numPools: @model.get('pools').length
        this

# Contains controls for navigating the page on the left
# sidebar
SidebarView = Backbone.View.extend

    events:
        # this is actually in the poolList view, butttt
        # make that thing late
        'click #new-pool': -> @trigger 'nav', {type: 'newPool'}

    initialize: ({@pools}) ->
        window.sidebar = this
        @poolList = new GenericView {
            template: poolTemplate, model: @pools
            id: 'dashboard-pool-list'
        }

    render: ->
        @$el.empty()
        @$el.html @poolList.render().el
        this

# Form for creating a new pool on the server
#
CreatePoolFormView = Backbone.View.extend

    events:
        'click #submit': 'submit'

    initialize: ->
        @template = createFormTemplate

    submit: (e) ->
        e.preventDefault()
        poolName = @$('#pool-name').val()
        console.log "submitting #{poolName}"
        false

    render: ->
        @$el.empty()
        @$el.html @template @model?.toJSON() or {}
        this
