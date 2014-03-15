# utility methods for the client
#

exports.get = ({resource, proj}, done) ->
    $.ajax
        url: "/#{resource}"
        method: 'get'
        data: { proj }
        headers: 'Content-Type': 'application/json'
        success: done