###
Module dependencies.
###
express     = require 'express'
routes      = require './routes'
http        = require 'http'
path        = require 'path'
app         = express()

projectRoot = path.resolve __dirname, '..'

# all environments
app.set 'port', process.env.PORT or 3001
app.set 'views', "#{projectRoot}/views"
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger 'dev'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, 'public'))

# development only
app.use express.errorHandler()  if 'development' is app.get('env')

# Define our display routes
app.get '/', routes.index
app.post '/login', routes.auth.login
app.get '/dashboard', ->

# Some API calls
app.get '/pools', ->
app.get '/pools/:id', ->

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')
  return