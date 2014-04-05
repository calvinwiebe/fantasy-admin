# Simple event emitter
#
class EventEmitter
    constructor: ->
        @listeners = {}

    # attach a listener to an event, and then return
    # `this` so caller can chain
    on: (event, listener) ->
        (@listeners[event] ?= []).push listener
        this

    removeListener: (event, listener) ->
        if @listeners[event]
            index = @listeners[event].indexOf listener
            @listeners[event].splice index, 1
            if @listeners[event].length is 0
                delete @listeners[event]

    emit: (event, data) ->
        if @listeners[event]
            for listener in @listeners[event]
                listener data

    put: (event, data) ->
        setTimeout =>
            @emit event, data
        , 0

# Export a single reference to be shared across the process
exports.Bus = new EventEmitter

# Export the class to support having multiple instances across the process
exports.EventEmitter = EventEmitter