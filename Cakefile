{spawn, exec} = require('child_process')

task 'build', 'compile coffeescripts', () ->
    exec "coffee -c -b public/*/*.coffee", (error, stdout, stderr) ->
        console.log(stdout)
        console.log(stderr)
        console.log("coffeescripts compiled")

# task 'server:start', 'starts the bstats_graphs server', () ->
#     exec "coffee -c -b public/*/*.coffee", (error, stdout, stderr) ->
#         console.log("coffeescripts compiled")
#         node = spawn "NODE_ENV=production node ./server.js"
#         node.stdout.on 'data', (data) -> console.log(data)
#         node.stderr.on 'data', (data) -> console.log(data)
#         process.on 'SIGINT', () -> node.kill 'SIGINT'
#
#
