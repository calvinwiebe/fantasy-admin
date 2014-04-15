# Emailing service module
emailer             = require 'nodemailer'
{events, rethink}   = require '../../lib'
poolUtils           = require '../../models/poolUtils'
emailTemplates      = require 'email-templates'
path                = require 'path'
templateDir         = path.resolve __dirname, '../../../templates'

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

eventsMap =
    'poolStart':
        domain: 'admin'
        template: 'poolStart'
    'newPicks':
        domain: 'users'
        template: 'newPicks'

transport = emailer.createTransport 'SMTP',
    service: 'Gmail'
    auth:
        user: 'calvin.wiebe@gmail.com'
        pass: 'vvrjcizasuncwcys'

# Read the template directory on init to save reading it for every email
# and start listening for email events.
#
exports.init = (done) ->
    bus.on 'email', handleEmailEvent
    emailTemplates templateDir, (err, template) ->
        templateFn = template
        done err

# Helper method to get a full pool object from the db
#
getPool = (id, done) ->
    rethink.getConnection (err, {conn, r}) ->
        poolUtils.get conn, r, id, done

getUsers = (filter, pool, done) ->

handleEmailEvent = ({type, poolId}) ->

    locals =
        name: 'Calvin'
        pool: 'Khello playoff pool'
        server: 'khello.ngrok.com'
        email: 'calvin.wiebe@gmail.com'
        password: 'blarg'

    templateFn 'poolStart', locals, (err, html, text) ->
        transport.sendMail {
            from: 'calvin.wiebe@gmail.com'
            to: 'calvin.wiebe@gmail.com'
            subject: "You have been added to #{locals.pool}"
            html: html
            text: text
        }, (err, res) ->
            console.error err if err
            console.log res.message
