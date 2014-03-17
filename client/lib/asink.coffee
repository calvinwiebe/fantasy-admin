# Async helper functions
_ = require 'lodash'

# Walk through a collection and pass each item to
# the `iterator`. Once all iterators have completed `done`
# will be called.
#
exports.each  = (collection, iterator, done) ->
    if _.isArray collection
        length = collection.length
        indices = (i for elem, i in collection)
    else if _.isObject collection
        keys = Object.keys collection
        length = keys.length
        indices = keys
    else
        done new Error 'collection must be array or object', null

    iterations = 0

    cb = (err) ->
        done err if err?
        ++iterations
        if iterations is length
            done null

    if indices.length
        for index in indices
            iterator collection[index], cb
    else
        done null

    return
