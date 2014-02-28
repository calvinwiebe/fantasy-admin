# Simple cake build file.
# Compiles coffee files in /src into /dist

fs = require 'fs'
path = require 'path'

{print} = require 'sys'
{spawn} = require 'child_process'

osify = (cmd) ->
    if process.platform is 'win32'
        cmd = cmd.replace '/', '\\'
    cmd

coffeeCmd = osify './node_modules/.bin/coffee'
ld = require 'lodash'
browserify = require 'browserify'
watchify = require 'watchify'

getSpawn = (cmd, args) ->
    if process.platform is 'win32'
        args = cmd + ' ' + args.join ' '
        spawned_cmd = spawn 'cmd', ['/c', args]
    else
        spawned_cmd = spawn cmd, args

    spawned_cmd

addListeners = (child) ->
    child.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    child.stdout.on 'data', (data) ->
        print data.toString()
    child.on 'exit', (code) ->
        if code isnt 0
            console.log 'child died abnormally'
            process.exit code
    child.on 'close', (code) ->
        console.log "Finished with code #{code}"
        if code isnt 0
            console.log 'child died abnormally'
            process.exit code

browserifyBundle = (fullPath, config, watch, debug=false) ->
    b = watchify fullPath
    b.require(r[0], expose: r[1]) for r in config.requires
    b.transform(t) for t in config.transforms
    bundle = b.bundle { debug }
    src = ""
    bundle.on 'data', (data) -> src += data
    bundle.on 'error', (err) ->
        console.log err
        process.exit -9
    if watch
        b.on 'update', (ids) ->
            console.log "BROWSERIFY: #{config.name}.coffee"
            b.bundle()
    bundle.on 'end', ->
        fs.writeFileSync path.join(__dirname, osify("public/javascripts/#{config.name}.js")), src

# build all the browserify bundles
#
browserifyBundles = (watch=false, debug=false) ->
    r =
        views: [ __dirname + osify('/client/lib/views.coffee'), 'views' ]

    configs = [
            name: 'landing'
            transforms: ['coffeeify', 'browserify-jade']
            requires: [
                r.views
            ]
        ,
            name: 'dashboard'
            transforms: ['coffeeify', 'browserify-jade']
            requires: [
                r.views
            ]
        ,
            name: 'jquery'
            transforms: ['coffeeify']
            requires: []
    ]

    ld.forEach configs, (config) ->
        fullPath = __dirname + osify("/client/bundles/#{config.name}/#{config.name}.coffee")
        browserifyBundle fullPath, config, watch, debug

# build all the server src files
build = (watch=false, debug=false) ->
    dist = osify 'dist/'
    src = osify 'src/'
    args = if watch then ['-w'] else []
    coffees = getSpawn coffeeCmd, args.concat ['-c', '-b', '-o', dist, src]
    addListeners coffees
    browserifyBundles(watch, debug)

run = (dev=false, debug=false) ->
    executable = if not dev then 'node' else 'nodemon'
    args = []
    if dev
        args.push '--debug' if debug
        args.push '--watch'
        args.push 'dist'
    args.push osify 'dist/app.js'
    node = getSpawn executable, args
    addListeners node

task 'build', 'Build dist from src', ->
    build()

task 'watch', 'Watch src for changes', ->
    build(true)

task 'dev', 'Watch src for changes and run node', ->
    process.env.NODE_ENV = 'development'
    build(true, true)
    run(true)

# If you want to debug server side code, run this task and then:
# 1. Once the app is up and running it should say 'debugger listening on port 5858'
# 2. You can connect via terminal with `node debug localhost:5858`
task 'debug', 'Watch src for changes and debug node', ->
    process.env.NODE_ENV = 'development'
    build(true, true)
    run(true, true)

task 'run', 'Build and run the project', ->
    process.env.NODE_ENV = 'production'
    build()
    run()

process.on 'exit', (code) ->
    console.log 'Process exiting'
    console.log code

process.on 'uncaughtException', (err) ->
    console.log "uncaughtException #{err}"
    process.exit -1

process.on 'SIGINT', ->
    console.log "Got interrupted. Probably by CTRL-C"
    process.exit 0
