# Simple cake build file.
# Compiles coffee files in /src into /dist

fs = require 'fs'
path = require 'path'

{print} = require 'sys'
{spawn} = require 'child_process'

coffeeCmd = './node_modules/.bin/coffee'
browserifyCmd = './node_modules/.bin/browserify'
ld = require 'lodash'
browserify = require 'browserify'

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
        callback?() if code is 0
    child.on 'close', (code) ->
        console.log "Finished with code #{code}"

# build all the browserify bundles
#
browserifyBundles = ->
    configs = [
            name: 'landing'
            transforms: ['coffeeify']
        ,
            name: 'dashboard'
            transforms: ['coffeeify', 'browserify-jade']
    ]

    ld.forEach configs, (config) ->
        b = browserify __dirname + "/client/bundles/#{config.name}/#{config.name}.coffee"
        b.require __dirname + '/client/lib/jquery-custom', expose: 'jquery-custom'
        b.transform(t) for t in config.transforms
        bundle = b.bundle(debug: true)
        src = ""
        bundle.on 'data', (data) -> src += data
        bundle.on 'error', (err) ->
            console.log err
            process.exit -9
        bundle.on 'end', ->
            fs.writeFileSync path.join(__dirname, "public/javascripts/#{config.name}.js"), src

build = (callback) ->
    # build all the server src files
    coffees = getSpawn coffeeCmd, ['-c', '-b', '-o', 'dist/', 'src/']
    addListeners coffees
    browserifyBundles()

watch = ->
    coffees = getSpawn coffeeCmd, ['-w', '-c', '-b', '-o', 'dist/', 'src/']

    [coffees].forEach addListeners

run = (debug=false) ->
    executable = if process.env.NODE_ENV is 'production' then 'node' else 'nodemon'
    args = []
    if process.env.NODE_ENV is 'development'
        args.push '--debug' if debug
        args.push '--watch'
        args.push 'dist'
    args.push 'dist/app.js'
    node = getSpawn executable, args
    addListeners node

task 'build', 'Build dist from src', ->
    build()

task 'watch', 'Watch src for changes', ->
    watch()

task 'dev', 'Watch src for changes and run node', ->
    process.env.NODE_ENV = 'development'
    watch()
    run()

# If you want to debug server side code, run this task and then:
# 1. Once the app is up and running it should say 'debugger listening on port 5858'
# 2. You can connect via terminal with `node debug localhost:5858`
task 'debug', 'Watch src for changes and debug node', ->
    process.env.NODE_ENV = 'development'
    watch()
    run(true)

task 'run', 'Build and run the project', ->
    process.env.NODE_ENV = 'production'
    build()
    run()
