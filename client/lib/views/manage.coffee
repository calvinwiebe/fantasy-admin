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
# To use, pass in the same object prototype you would for creating a `Backbone.View`.
# This function will extend that prototype with its properties, and propagate the result
# to the `Backbone.View.extend` constructor.
#
# To start using the `swapping` methods, in your `initialize` method, call `configureSwap` with
# an options hash such as this:
# ```
# header = {
#     root: 'body'
#     view: HeaderView
#     method: 'prepend'
#     isStatic: true
#     name: 'header'
# }
# @configureSwap
#     event: 'nav'
#     default: 'home'
#     map:
#         'standings': views: [
#             header
#             StandingsView
#         ]
#         'picks': views: [
#             header
#             PicksView
#         ]
#         'home': views: [
#             PoolListView
#         ]
# ```
#
exports.Swapper = (proto) ->

    # Prototype object
    #
    _super =

        # Start managing ourselves
        #
        configureSwap: (@_swapper_config) ->
            @views = []
            @state = @_swapper_config.default
            @_swapper_firstRender = true

        # helper method for below functions
        #
        getConfig: ->
            return @_swapper_config

        # The event handler that delegates to `render`
        #
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

        # Get the collections of the managed views that are currently rendered/visible.
        # This can be used by the "sub-classing" function
        #
        getCollections: ->
            _.chain(@views) \
                .map((view) ->
                    name: view.__swapper_context__.name
                    collection: view.collection
                ).reduce((result, obj) ->
                    result[obj.name] = obj.collection
                    result
                , {})
                .value()

        # If using the `name` option in the config hash, you can grab a view
        # by its name
        #
        getView: (name) ->
            _.find @views, (view) -> view.__swapper_context__.name is name

        # if the view is isStatic, and already exists, retain the view instance
        #
        leaveAlone: ({name, isStatic}) ->
            if name and isStatic?
                return current if current = _.find(@views,
                    (view) -> view.__swapper_context__.name is name)

        # From the new config, as per the state, map the config options
        # into their corresponding view instances
        #
        mapViews: ->
            try
                viewConfigs = @_swapper_config.map[@state].views
            catch err
                console.warn? "Swapper could not find config for state #{@state}"
                return
            views = viewConfigs \
                .map((config) =>
                    if typeof config is 'function'
                        view = config
                    else
                        if current = @leaveAlone config
                            current.__swapper_context__.leaveAlone = true
                            return current
                        {root, view, method, name, isStatic} = config

                    view = new view { @model, @collection, @context, parent: this }
                    view.__swapper_context__ = {
                        name
                        isStatic
                        root
                        method
                    }
                    view
                )

            @viewsToRemove = _.difference @views, views
            @views = views

        # Called by `render`. This will remove all the views that are being swapped out
        # or are `static`
        #
        removeViews: ->
            @viewsToRemove?.forEach((view) =>
                 view.remove()
            )

        # Take the mapped view instances and add them to the DOM
        #
        renderViews: ->
            event = @_swapper_config.event
            @stopListening()
            @views.forEach (view) =>
                { name, isStatic, root, method, leaveAlone } = view.__swapper_context__
                root = \
                    if @$(root).length
                        root = @$(root)
                    else if $(root).length
                        root = $(root)
                    else
                        @$el
                @listenTo view, event, @onSwap
                @listenTo view, 'bubble', @bubbleUp
                return if leaveAlone
                method = if root[method]? then method else 'append'
                root[method] view.render().el
            @listenTo this, event, @onSwap

        # Called when a swap event is fired. This will recreate the content
        # as per the configurations
        #
        render: ->
            @undelegateEvents()
            @beforeRender?()
            @$el.html @template? \
                @_swapper_config.map[@state].template ? \
                @serialize?() ? \
                @model?.toJSON() ? \
                {} if @_swapper_firstRender
            @_swapper_firstRender = false
            @mapViews()
            @removeViews()
            @renderViews()
            @afterRender?()
            @delegateEvents()
            this

    # Extend the `Swapper` functionality with the subclass and
    # create the `Backbone.View` function
    proto = _.extend _super, proto
    return View proto
