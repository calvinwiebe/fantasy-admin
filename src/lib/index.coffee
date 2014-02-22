
# Simple method to create a resource from a module of routes
#
exports.makeResourceful = (app) ->
    app.resource = (resource, resourceModule) ->
        app.get "/#{resource}", resourceModule.index
        app.get "/#{resource}/new", resourceModule.new
        app.post "/#{resource}", resourceModule.create
        app.get "/#{resource}/:id", resourceModule.show
        app.del "/#{resource}/:id", resourceModule.destroy