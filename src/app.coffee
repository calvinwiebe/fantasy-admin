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
app.use express.bodyParser()
app.use express.methodOverride()
# sessions middleware
app.use sessions
    cookieName: 'session'
    secret: 'khelloClammers9000'
    duration: 60 * 20 * 1000 # 20 minute sessions
    secure: false
# connect to our rethinkDB and add the connection to the `req` object
app.use middleware.rethink()

###
ROUTES
###

rootUrl = '/'
successUrl = '/dashboard'
# Define our display routes
app.get '/', routes.index
app.post '/login', routes.auth.login(rootUrl, successUrl)
app.get '/logout', routes.auth.logout(rootUrl)

# everything else needs a user
requireUser = middleware.requireUser(rootUrl)
app.get '/dashboard', requireUser, routes.dashboard.index

# Some API calls
app.get '/pools', requireUser, ->
app.get '/pools/:id', requireUser, ->

###
STATIC
###

app.use express.static(path.join(__dirname, 'public'))
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