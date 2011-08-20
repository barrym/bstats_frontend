async   = require('async')
express = require('express')
app     = express.createServer()
app.use(express.static("#{__dirname }/public"))
app.listen(8888)

io                = require('socket.io').listen(app)
redis             = require('redis').createClient()
offset            = 2

connected_sockets = io.sockets.on('connection', (socket) ->
    console.log("socket client connected")
)

per_second_sockets = io.of('/per_second').on('connection', (socket) ->
    console.log("per second client connected")
    init_per_second_data(socket, 300)
)

setInterval(
    () ->
        now = timestamp() - offset
        send_per_second_data(per_second_sockets, [now])
, 1000)

# --------------- PER SECOND ------------------ #
#
init_per_second_data = (sockets, data_points) ->
    now = timestamp() - offset
    timestamps = [(now - data_points)...now]
    send_per_second_data(sockets, timestamps)

send_per_second_data = (sockets, timestamps) ->
    async.map(timestamps, get_per_second_data_for_timestamp, (err, results) ->
        flattened_results = results.reduce((a, b) ->
            a.concat(b)
        )
        send_data(sockets, 'bstat_counters', flattened_results)
    )
    console.log("done")

get_per_second_data_for_timestamp = (timestamp, callback) ->
    perform_on_all_counters((counters) ->
        keys = counters.map((counter) -> "bstats:counter:#{counter}:#{timestamp}")

        redis.mget(keys, (err, res) ->
            message = counters.map((counter, i) ->
                {
                    counter  : counter,
                    time     : timestamp,
                    value    : parseInt(res[i]) || 0
                }
            )

            message.push(
                {
                    counter  : "no_data",
                    time     : timestamp,
                    value    : 0
                }
            )
            callback(null, message)
        )
    )

# ----------------------- INTERNAL ------------------------

perform_on_all_counters = (fun) ->
    redis.smembers("bstats:counters", (err, counters) ->
        counters = counters ?= []
        fun(counters)
    )

send_data = (sockets, channel, message) ->
    sockets.emit(channel, message)

timestamp = () ->
    Math.round(new Date().getTime() / 1000)
