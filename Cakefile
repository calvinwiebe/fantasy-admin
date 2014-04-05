# Simple cake build file.
# Compiles coffee files in /src into /dist

fs = require 'fs'
path = require 'path'

{print} = require 'sys'
{spawn} = require 'child_process'

osify = (cmd) ->
    if process.platform is 'win32'
        cmd = cmd.replace /\//g, '\\'
    cmd
coffeeCmd = osify './node_modules/.bin/coffee'
ld = require 'lodash'
browserify = require 'browserify'
watchify = require 'watchify'

# keep track of children and kill them if the parent
# dies
spawns = []

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

writeBundleToDisk = (config, src) ->
    console.log "writing #{config.name} to disk"
    fs.writeFileSync path.join(__dirname, osify("public/javascripts/#{config.name}.js")), src

browserifyBundle = (fullPath, config, watch, debug=false) ->
    if watch
        b = watchify fullPath
    else
        b = browserify fullPath
    b.require(r[0], expose: r[1]) for r in config.requires
    b.transform(t) for t in config.transforms
    bundle = b.bundle { debug }
    doBundle = (bundle) ->
        src = ""
        bundle.on 'data', (data) -> src += data
        bundle.on 'error', (err) ->
            console.log err
            process.exit -9
        bundle.on 'end', ->
            writeBundleToDisk config, src

    if watch
        b.on 'update', (ids) ->
            console.log "BROWSERIFY: #{config.name}.coffee"
            doBundle b.bundle()

    doBundle bundle

# build all the browserify bundles
#
browserifyBundles = (watch=false, debug=false) ->
    r =
        underscore: [ 'lodash', 'underscore' ]

    configs = [
            name: 'landing'
            transforms: ['coffeeify', 'aliasify', 'browserify-jade']
            requires: [
                r.underscore
            ]
        ,
            name: 'adminDashboard'
            transforms: ['coffeeify', 'aliasify', 'browserify-jade', 'rfolderify']
            requires: [
                r.underscore
            ]
        ,
            name: 'userDashboard'
            transforms: ['coffeeify', 'aliasify', 'browserify-jade', 'rfolderify']
            requires: [
                r.underscore
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
    spawns.push coffees
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
    spawns.push node

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
    if code isnt 0
        spawns.forEach (s) ->
            s.kill()

process.on 'uncaughtException', (err) ->
    console.log "uncaughtException #{err}"
    process.exit -1

process.on 'SIGINT', ->
    console.log "Got interrupted. Probably by CTRL-C"
    process.exit 0
