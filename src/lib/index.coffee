# Common functions to be used throughout the project
#
_       = require 'lodash'
fs      = require 'fs'
path    = require 'path'
crypto  = require 'crypto'

# Require all the files in a directory and add them to an
# object. By default, it will skip anything named `index`.
#
exports.requireAll = requireAll = (rootPath) ->
    modules = {}
    _.chain(fs.readdirSync(rootPath))
        .map((file) -> file.slice(0, file.lastIndexOf '.'))
        .uniq()
        .filter((file) -> not /index/.test file)
        .forEach (m) ->
            modules[m] = require path.join rootPath, m
    return modules

# Simple method to create a resource from a module of routes
#
exports.makeResourceful = (app) ->
    app.resource = (resource, resourceModule, {write, any, protect}) ->
        app.get "/#{resource}", protect(any), resourceModule.index
        app.get "/#{resource}/new", protect(write), resourceModule.new
        app.post "/#{resource}", protect(write), resourceModule.create
        app.get "/#{resource}/:id", protect(any), resourceModule.show
        app.put "/#{resource}/:id", protect(write), resourceModule.update
        app.del "/#{resource}/:id", protect(write), resourceModule.destroy

# Common password hash function using `sha256`
#
exports.hashPassword = (password) ->
    crypto.createHash('sha256')
        .update(password)
        .digest('hex')

_.extend exports, requireAll __dirname
