# Functions/Mixin/Classes for managing Backbone Views
#
Backbone        = require 'backbone'
Backbone.$      = window.$
_               = require 'lodash'

View = Backbone.View.extend.bind Backbone.View

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

        # Bubble up an event, as there may be Swappers inside swappers.
        # If an object defines a `onBubble`, they can intercept the bubble.
        # The `onBubble` should return a boolean. `true` for continue bubbling, and
        # `false` to not.
        #
        bubbleUp: (data) ->
            if @onBubble?(data) ? true
                @trigger 'bubble', data

        getCollections: ->
            _.chain(@views) \
                .map((view) ->
                    name: view.name
                    collection: view.collection
                ).reduce((result, obj) ->
                    result[obj.name] = obj.collection
                    result
                , {})
                .value()

        getView: (name) ->
            _.find @views, { name }

        removeCurrent: ->
            @views.forEach((view) =>
                view.remove()
            )

        renderContent: ->
            try
                views = @_swapper_config.map[@state].views
            catch err
                console.warn? "Swapper could not find config for state #{@state}"
                return
            event = @_swapper_config.event
            @stopListening()
            @views = views \
                .map((config) =>
                    if typeof config is 'function'
                        view = config
                    else
                        {root, view, method, name} = config
                    view = new view { @model, @collection, @context, parent: this }
                    view.name = name
                    root = \
                        if @$(root).length
                            root = @$(root)
                        else if $(root).length
                            root = $(root)
                        else
                            @$el
                    @listenTo view, event, @onSwap
                    @listenTo view, 'bubble', @bubbleUp
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
                @_swapper_config.map[@state].template ? @serialize?() ? @model?.toJSON() ? {} if @_swapper_firstRender
            @_swapper_firstRender = false
            @renderContent()
            @afterRender?()
            @delegateEvents()
            this

    proto = _.extend _super, proto

    return View proto
