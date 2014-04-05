
# Show the dashboard front page
#
exports.admin = (req, res, next) ->
    res.render 'adminDashboard', app: 'admin'

exports.client = (req, res, next) ->
    res.render 'userDashboard', app: 'fantasy'