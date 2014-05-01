###
Module dependencies.
###
express     = require 'express'
routes      = require './routes'
http        = require 'http'
path        = require 'path'
app         = express()
sessions    = require 'client-sessions'
dbService   = require './services/db'
emailService= require './services/email'
middleware  = require './middleware'
{makeResourceful} = require './lib'
makeResourceful app

projectRoot = path.resolve __dirname, '..'

# all environments
app.set 'port', process.env.PORT or 3001
app.set 'views', "#{projectRoot}/views"
app.set 'view engine', 'jade'

isDebug = 'production' isnt app.get('env')

###
MIDDLEWARE
###

app.use express.favicon()
app.use express.logger 'dev' if isDebug
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
# sessions middleware
sessionDuration = \
    if isDebug
        60 * 1000 * 60 * 24 * 7 # a week for dev
    else
        60 * 1000 * 240 # 4 hr minute sessions for prod

app.use sessions
    cookieName: 'session'
    secret: 'khelloClammers9000'
    duration: sessionDuration
    secure: false
# connect to our rethinkDB and add the connection to the `req` object
app.use middleware.rethink()
app.use middleware.populateUser

###
ROUTES
###

requireUser = middleware.requireUser { isDebug }

# Define our login routes
app.get '/', routes.auth.forward, routes.index
app.post '/login', routes.auth.login
app.get '/logout', routes.auth.logout

# password reset route
app.get '/reset', requireUser('*', '/'), routes.passwordReset
app.post '/passReset', requireUser('*', '/'), routes.auth.passwordReset

# admin dashboard
app.get '/admin/dashboard', requireUser('admin', '/'), routes.dashboard.admin

# client dashboard
app.get '/pool/dashboard', requireUser('pool', '/'), routes.dashboard.client

# Resources: these are used for both the admin and client. The client users
# are restricted to 'readonly' mode (can only hit GETs).
for name, resource of routes.resources
    app.resource name, resource,
        write: 'admin'
        any: '*'
        protect: requireUser

# Client Resources: these are used for both admin and the client, but mainly for client.
# We allow the user to CRUD these.
for name, resource of routes.clientResources
    app.resource name, resource,
        write: '*'
        any: '*'
        protect: requireUser

###
STATIC
###
app.use express.static(path.join(__dirname, '..', 'public'))
app.use app.router

# development only
app.use express.errorHandler() if 'development' is app.get('env')

###
START
###

# Create our db and tables if they aren't created yet
dbService.initialize ->
    emailService.init (err) ->
        console.error 'Failed to load email templates', err if err?
        http.createServer(app).listen app.get('port'), ->
            console.log 'Express server listening on port ' + app.get('port')
