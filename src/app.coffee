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
middleware  = require './middleware'
{makeResourceful} = require './lib'
makeResourceful app

projectRoot = path.resolve __dirname, '..'

# all environments
app.set 'port', process.env.PORT or 3001
app.set 'views', "#{projectRoot}/views"
app.set 'view engine', 'jade'

###
MIDDLEWARE
###

app.use express.favicon()
app.use express.logger 'dev'
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
# sessions middleware
app.use sessions
    cookieName: 'session'
    secret: 'khelloClammers9000'
    duration: 60 * 20 * 1000 # 20 minute sessions
    secure: false
# connect to our rethinkDB and add the connection to the `req` object
app.use middleware.rethink()
app.use middleware.populateUser

###
ROUTES
###

requireUser = middleware.requireUser isDebug: 'production' isnt app.get('env')

# Define our login routes
app.get '/', routes.auth.forward, routes.index
app.post '/login', routes.auth.login
app.get '/logout', routes.auth.logout

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
    http.createServer(app).listen app.get('port'), ->
      console.log 'Express server listening on port ' + app.get('port')
      return