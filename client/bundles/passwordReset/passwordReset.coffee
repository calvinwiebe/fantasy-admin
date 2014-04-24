templates       = rfolder './templates', extensions: [ '.jade' ]
{genericRender} = require 'views'
Backbone        = require 'backbone'
Backbone.$      = window.$
_               = require 'lodash'

PasswordReset = Backbone.View.extend
    template: templates.passwordReset

    events:
        'click #reset': 'reset'

    # TODO use bootstrap alerts
    alert: (type, msg) ->
        alert msg

    reset: (e) ->
        e.preventDefault()
        currentPassword = @$('#current').val()
        newPassword = @$('#new').val()
        confirmPassword = @$('#confirm').val()
        unless newPassword is confirmPassword
            @alert 'error', 'Passwords do not match.'
            return false
        $.post('/passReset', {
            currentPassword
            newPassword
            confirmPassword
        }).done((responseJSON) =>
            @alert 'success', responseJSON.msg
        ).fail(({responseJSON}) =>
            @alert 'error', responseJSON.error
        )
        false

    render: genericRender

$ ->
    view = new PasswordReset
    $('.content').append view.render().el
