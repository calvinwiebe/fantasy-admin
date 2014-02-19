# Simple cake build file.
# Compiles coffee files in /src into /dist

fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

coffeeCmd = './node_modules/.bin/coffee'

getSpawn = (cmd, args) ->
    if process.platform is 'win32'
        args = cmd + ' ' + args.join ' '
        spawned_cmd = spawn 'cmd', ['/c', args]
    else
        spawned_cmd = spawn cmd, args

    spawned_cmd

build = (callback) ->
    coffees = getSpawn coffeeCmd, ['-c', '-b', '-o', 'dist/', 'src/']

    [coffees].forEach (spawnInstance) ->
        spawnInstance.stderr.on 'data', (data) ->
            process.stderr.write data.toString()
        spawnInstance.stdout.on 'data', (data) ->
            print data.toString()
        spawnInstance.on 'exit', (code) ->
            callback?() if code is 0

watch = ->
    coffees = getSpawn coffeeCmd, ['-w', '-c', '-b', '-o', 'dist/', 'src/']

    [coffees].forEach (spawnInstance) ->
        spawnInstance.stderr.on 'data', (data) ->
          process.stderr.write data.toString()
        spawnInstance.stdout.on 'data', (data) ->
          print data.toString()

run = (debug=false) ->
    executable = if process.env.NODE_ENV is 'production' then 'node' else 'nodemon'
    args = []
    if process.env.NODE_ENV is 'development'
        args.push '--debug' if debug
        args.push '--watch'
        args.push 'dist'
    args.push 'dist/app.js'
    node = getSpawn executable, args
    node.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    node.stdout.on 'data', (data) ->
      print data.toString()
    node.on 'exit', (code) ->
        process.exit code

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
