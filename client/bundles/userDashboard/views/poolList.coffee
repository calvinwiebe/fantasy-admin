Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
# templates
templates = rfolder '../templates', extensions: [ '.jade' ]
# views
{GenericView, genericRender, Cleanup} = require 'views'
# utils
utils = require 'utils'
# models
{PoolModel} = require 'models'
View = Backbone.View.extend.bind Backbone.View

exports.PoolListView = View
    id: 'pool-list'
    template: templates.poolList

    render: genericRender
