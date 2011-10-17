{spawn, exec} = require('child_process')

task 'build', 'compile coffeescripts', () ->
    exec "coffee -c -b public/*/*.coffee", (error, stdout, stderr) ->
        console.log(stdout)
        console.log(stderr)
        console.log("coffeescripts compiled")

task 'server:start', 'start the server', () ->
    server = exec "./node_modules/forever/bin/forever start server.js"
    server.stdout.on 'data', (data) -> console.log(data)


task 'server:list', 'list server status', () ->
    server = exec "./node_modules/forever/bin/forever list"
    server.stdout.on 'data', (data) -> console.log(data)


task 'server:stop', 'stop the server', () ->
    server = exec "./node_modules/forever/bin/forever stop server.js"
    server.stdout.on 'data', (data) -> console.log(data)

# task 'server:start', 'starts the bstats_graphs server', () ->
#     exec "coffee -c -b public/*/*.coffee", (error, stdout, stderr) ->
#         console.log("coffeescripts compiled")
#         node = spawn "NODE_ENV=production node ./server.js"
#         node.stdout.on 'data', (data) -> console.log(data)
#         node.stderr.on 'data', (data) -> console.log(data)
#         process.on 'SIGINT', () -> node.kill 'SIGINT'
#
#
