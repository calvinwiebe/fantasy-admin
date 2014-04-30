email       = require '../src/services/email'
commander   = require 'commander'

commander
    .version('0.0.1')
    .option('-t, --type <type>', 'email type/event')
    .option('-p, --pool <pool>', 'poolId for poolStart event')
    .parse process.argv

email.init (err) ->

    if err?
        console.log err
        process.exit -1

    {type, pool} = commander

    data = {}
    data.type = type

    switch type
        when 'poolStart'
            unless pool?
                console.log 'Need a pool id for type:poolStart'
                process.exit -1
            data.pool = pool

    email.handleEmailEvent data, force: true, done: (err) ->
        console.log err if err?
        process.exit 0
