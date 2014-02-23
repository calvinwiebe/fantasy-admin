template = require './landingTemplate.jade'
{GenericView} = require 'views'

$ ->
    view = new GenericView { template }
    $('.content').append view.render().el

