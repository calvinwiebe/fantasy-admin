Backbone = require 'backbone'
Backbone.$ = window.$
contentTemplate = require './content.jade'
headerTemplate = require './header.jade'
poolTemplate = require './poolList.jade'
actionAreaTemplate = require './actionArea.jade'
{GenericView} = require 'views'

exports.DashboardContentView = Backbone.View.extend
    id: 'dashboard'

    initialize: ({@pools}) ->

    render: ->
        @headerView = new GenericView {
            template: headerTemplate
            id: 'dashboard-header'
            className: 'navbar navbar-inverse navbar-fixed-top'
        }
        @poolList = new GenericView {
            template: poolTemplate, model: @pools
            id: 'dashboard-pool-list'
        }
        @actionArea = new GenericView {
            template: actionAreaTemplate
            id: 'dashboard-action-area'
        }
        @$el.empty()
        @$el.append @headerView.render().el
        @$el.append contentTemplate()
        @$('#sidebar-content').append @poolList.render().el
        @$('#action-area-content').append @actionArea.render().el
        console.log  @$el
        this