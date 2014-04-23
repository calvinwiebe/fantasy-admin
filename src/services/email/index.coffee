# Emailing service module
_                               = require 'lodash'
async                           = require 'async'
emailer                         = require 'nodemailer'
{events, rethink, requireAll}   = require '../../lib'
emailTemplates                  = require 'email-templates'
path                            = require 'path'
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

# TODO - load this from a non-source controlled config file
sender = 'calvin.wiebe@gmail.com'
transport = emailer.createTransport 'SMTP',
    service: 'Gmail'
    auth:
        user: sender
        pass: 'vvrjcizasuncwcys'

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
handleEmailEvent = (data) ->
    {type} = data
    try
        handlers[type] data, (err, {recipients, locals, subject}) ->
            return if err?
            async.each recipients, (recipient, cb) ->
                recipientLocals = _.extend {}, locals, { recipient }
                templateFn type, recipientLocals, (err, html, text) ->
                    return cb err if err?
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
                console.log "successfully sent all emails for #{type}"
    catch err
        console.error "Error processing email event #{type}", err
