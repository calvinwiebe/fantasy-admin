_ = require 'lodash'
children =
    reusable: require './reusable.coffee'
    manage: require './manage.coffee'
module.exports = _.reduce children, (result, child) ->
    _.extend result, child
, {}
