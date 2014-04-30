# Emailing service module
_                               = require 'lodash'
async                           = require 'async'
emailer                         = require 'nodemailer'
{events, rethink, requireAll}   = require '../../lib'
emailTemplates                  = require 'email-templates'
path                            = require 'path'
config                          = require '../../config'
templateDir                     = path.resolve __dirname, '../../../templates'
handlers                        = requireAll path.resolve __dirname, 'handlers'
# Listen for app-wide for `email` events. These events should follow
# this convention
#
# bus.emit 'email', {
#     type: poolStart/picksEntered
#     pool: poolId
# }
#
# The `domain` is the group type of users that should get the mail
#
bus = events.getEventBus 'email'
templateFn = null

sender = config.email.sender
transport = emailer.createTransport config.email.serviceTransport,
    service: config.email.service
    auth:
        user: sender
        pass: config.email.serviceAuth

# Read the template directory on init to save reading it for every email
# and start listening for email events.
#
exports.init = (done) ->
    bus.on 'email', handleEmailEvent
    emailTemplates templateDir, (err, template) ->
        templateFn = template
        done err

# Handle the emitted event: Compile all the local vars needed
# for the email template using its associated handler. Then send the
# email.
#
exports.handleEmailEvent = handleEmailEvent = (data, {force, done}={}) ->
    force ?= false
    {type} = data
    return if type in config.email.manual unless force
    try
        handlers[type] data, (err, {recipients, locals, subject}) ->
            if err?
                return console.error "Error processing email event #{type}", err
            async.each recipients, (recipient, cb) ->
                recipientLocals = _.extend {}, locals, { recipient }
                templateFn type, recipientLocals, (err, html, text) ->
                    return cb err if err?
                    # TODO - make the `transport` object handle the `testMode` stuff, so this
                    # code doesn't have the conditional. i.e. instantiate either a testTransport or
                    # a real one.
                    if config.email.testMode
                        console.log 'Email test mode output:'
                        console.log html
                    else
                        transport.sendMail {
                            from: sender
                            to: recipient.email
                            subject: subject
                            html: html
                            text: text
                        }, (err, res) ->
                            return cb err if err
                            console.log res.message
                            cb null
            , (err) ->
                if err?
                    console.error "Error processing email event #{type}", err
                else
                    console.log "successfully sent all emails for #{type}"
                done?()
    catch err
        console.error "Error processing email event #{type}", err
        done?(err)
