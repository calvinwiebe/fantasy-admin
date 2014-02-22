
# Show the dashboard front page
#
exports.index = (req, res, next) ->
    console.log 'dashboard url'
    res.send 'You have logged in! Create a pool!'