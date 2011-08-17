http = require('http')
io   = require('socket.io')
url  = require('url')
path = require('path')
mime = require('mime')
fs   = require('fs')
qs   = require('querystring')

# SERVE PAGES
httpServer = http.createServer((request, response) ->
    pathname = url.parse(request.url).pathname;
    filename = null
    if pathname == "/"
        filename = "public/index.html"
    else
        filename = path.join(process.cwd(), 'public', pathname)

    path.exists(filename, (exists) ->
        if(!exists)
            response.writeHead(404, {'Content-Type':'text/plain'})
            response.write("404 not found")
            response.end()
            return

        response.writeHead(200, {'Content-Type':mime.lookup(filename)})
        fs.createReadStream(filename, {
            'flags':'r',
            'encoding':'binary',
            'mode':'0666',
            'bufferSize':4 * 1024
        }).addListener('data', (chunk) ->
            response.write(chunk, 'binary')
        ).addListener('close', () ->
            response.end()
        )
    )
)

httpServer.listen('8888')

# SOCKET.IO DATA PUSHES
io           = io.listen(httpServer)
redis        = require('redis')
redisClient  = redis.createClient()
offset = 2
connected_sockets = []


io.sockets.on('connection', (socket) ->
    console.log("socket client connected")
    connected_sockets.push(socket)
)

totals_sockets = io.of('/totals').on('connection', (socket) ->
    console.log("totals client connected")
    init_totals_data(socket)
)


per_second_sockets = io.of('/per_second').on('connection', (socket) ->
    console.log("per second client connected")
    init_per_second_data(socket)
)

setInterval(
    () ->
        now = timestamp() - offset
        send_per_second_data(per_second_sockets, now)
        send_totals_data(totals_sockets)
, 1000)


perform_on_all_counters = (fun) ->
    redisClient.smembers("bstats:counters", (err, counters) ->
        counters = counters ?= []
        fun(counters)
    )

send_per_second_data = (sockets, now) ->
    perform_on_all_counters((counters) ->
        keys = counters.map((counter) -> "bstats:#{counter}:#{now}")

        redisClient.mget(keys, (err, res) ->
            message = counters.map((counter, i) ->
                {
                    counter  : counter,
                    time     : now,
                    value    : parseInt(res[i]) || 0
                }
            )

            message.push(
                {
                    counter  : "no_data",
                    time     : now,
                    value    : 0
                }
            )

            sockets.emit('bstat_counters', message)
        )
    )

send_totals_data = (sockets) ->
    perform_on_all_counters((counters) ->
        keys = counters.map((counter) -> "bstats:#{counter}:total")

        redisClient.mget(keys, (err, res) ->
            message = counters.map((counter, i) ->
                {
                    counter  : counter,
                    value    : parseInt(res[i]) || 0
                }
            )

            message.push(
                {
                    counter  : "no_data",
                    value    : 0
                }
            )

            sockets.emit('bstat_counter_totals', message)
        )
    )

init_per_second_data = (socket) ->
    now = timestamp() - offset
    send_per_second_data(socket, t) for t in [(now - 60)..now]

init_totals_data = (socket) ->
    send_totals_data(socket)

timestamp = () ->
    Math.round(new Date().getTime() / 1000)
