
# Show the dashboard front page
#
exports.admin = (req, res, next) ->
    res.render 'adminDashboard'

exports.client = (req, res, next) ->
    res.render 'userDashboard'