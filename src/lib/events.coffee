# Event buses for the application
{EventEmitter} = require 'events'
buses = {}

# Create an app-wide event bus
exports.getEventBus = (name) ->
    return buses[name] if buses[name]?

    bus = new EventEmitter
    buses[name] = bus

    return bus
