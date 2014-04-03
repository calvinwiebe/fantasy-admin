
# Show the dashboard front page
#
exports.admin = (req, res, next) ->
    res.render 'dashboard'

exports.client = (req, res, next) ->
    res.send 'Helloooo client!'