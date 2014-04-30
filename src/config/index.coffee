# Coffee configuration object.
#

# register coffee-script so we can require non-built config files
require 'coffee-script/register'
_  = require 'lodash'

defaults =
    db:
        address: 'localhost'
        port: 28015
        adminDb:
            name: 'admin'
            tables: [
                'users'
                'poolTypes'
                'pools'
                'rounds'
                'series'
                'categories'
                'results'
                'teams'
                'picks'
                'pendingPicks'
            ]
        fantasyDb:
            name: 'fantasy'
        email:
            manual: []

# Environment specific configs
switch process.env.NODE_ENV
    when 'production'   then  srcOverrides = require './production'
    when 'development'  then  srcOverrides = require './development'
    when 'test'         then  srcOverrides = require './test'
    else                      srcOverrides = {}

# This is a per-machine config that isn't source controlled.
localOverrides = require '../../localConfigs'

module.exports = _.merge defaults, srcOverrides, localOverrides
