# Backbone models for the dashboard
#
Backbone = require 'backbone'
Backbone.$ = window.$

exports.PoolModel = Backbone.Model.extend
    url: '/pool'