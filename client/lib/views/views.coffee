Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
listItem    = require './listItem.jade'
inputListItem    = require './inputListItem.jade'

View = Backbone.View.extend.bind Backbone.View

exports.genericRender = genericRender = ->
    @undelegateEvents()
    @$el.empty()
    if @serialize?
        data = @template @serialize @model
    else if @collection? and @model?
        data = @template _.extend @model.toJSON(), models: @collection.toJSON()
    else if @collection?
        data = @template models: @collection.toJSON()
    else if @model?
        data = @template @model.toJSON()
    else
        data = @template {}
    @$el.html data
    @delegateEvents()
    this

exports.GenericView = View
    initialize: ({@template}) ->
    render: genericRender

# A generic view to show a list item in a list-group
# If it is clicked, it will trigger an event with its model
#
exports.ListItem = View
    tagName: 'li'
    className: 'list-group-item'
    template: listItem

    events:
        'click': 'onClick'

    initialize: ({@serialize}) ->

    onClick: ->
        @trigger 'selected', @model

    render: genericRender

# A generic view to show a bunch of input items, with a model attached
# to them. When the view is blurred, it will set the value of the single input
# on the model's `value` attr
#
exports.InputListItem = View
    className: 'input-group'
    template: inputListItem

    events:
        'blur input': 'onBlur'

    initialize: ({@serialize}) ->

    onBlur: ->
        @model.set 'value', @$('input').val()

    render: genericRender

Cleanup = {}
Cleanup.mixin =
    cleanUp: ->
        @childViews.forEach (child) =>
            @stopListening child
            child.remove()
        @childViews.length = 0

    remove: ->
        @cleanUp()
        Backbone.View.prototype.remove.call this

exports.Cleanup = Cleanup

# A Swapper view:
# This will is in charge of swapping a `content` view depending on
# the state.
#
exports.Swapper = (proto) ->
    _super =
        configureSwap: (@_swapper_config) ->
            @views = []
            @state = @_swapper_config.default
            @_swapper_firstRender = true

        getConfig: ->
            return @_swapper_config

        onSwap: ({@state, @context}) ->
            @render()

        removeCurrent: ->
            @views.forEach (view) =>
                view.remove()
            @views.length = 0

        renderContent: ->
            views = @_swapper_config.map[@state].views
            event = @_swapper_config.event
            @stopListening()
            @views = views \
                .map((config) =>
                    if typeof config is 'function'
                        view = config
                    else
                        {root, view, method} = config
                    view = new view { @model, @collection, @context }
                    root = \
                        if @$(root).length
                            root = @$(root)
                        else if $(root).length
                            root = $(root)
                        else
                            @$el
                    @listenTo view, event, @onSwap
                    method = if root[method]? then method else 'append'
                    root[method] view.render().el
                    view
                )
            @listenTo this, event, @onSwap

        render: ->
            @undelegateEvents()
            @removeCurrent()
            @beforeRender?()
            @$el.html @template? \
                @_swapper_config.map[@state].template ? {} if @_swapper_firstRender
            @_swapper_firstRender = false
            @renderContent()
            @afterRender?()
            @delegateEvents()
            this

    proto = _.extend _super, proto

    return View proto

