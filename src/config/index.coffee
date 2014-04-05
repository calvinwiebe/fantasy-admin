# Coffee configuration object.
#

_  = require 'lodash'
try
    {customDB} = require './custom'
catch
    customDB = {}
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
            ]
        fantasyDb:
            name: 'fantasy'

# not a deep clone soooo any objects in DB would be fully copied over without using any defaults
defaults.db = _.defaults customDB, defaults.db

module.exports = defaults