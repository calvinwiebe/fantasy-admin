# Backbone models for the dashboard
#
Backbone = require 'backbone'
Backbone.$ = window.$

exports.PoolModel = Backbone.Model.extend
    url: '/pools'

exports.PoolCollection = Backbone.Collection.extend
    url: '/pools'