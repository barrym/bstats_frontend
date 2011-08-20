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
        send_counter_data(per_second_sockets, [now])
, 1000)

# --------------- PER SECOND ------------------ #
#
init_per_second_data = (sockets, data_points) ->
    now = timestamp() - offset
    timestamps = [(now - data_points)...now]
    send_counter_data(sockets, timestamps)

send_counter_data = (sockets, timestamps) ->
    async.map(timestamps, get_counter_data_for_timestamp, (err, results) ->
        flattened_results = results.reduce((a, b) ->
            a.concat(b)
        )
        send_data(sockets, 'bstat_counters', flattened_results)
    )

get_counter_data_for_timestamp = (timestamp, callback) ->
    perform_on_all_counters((counters) ->
        keys = counters.map((counter) -> "bstats:counter:#{counter}:#{timestamp}")

        redis.mget(keys, (err, res) ->
            objects = counters.map((counter, i) ->
                {
                    counter  : counter,
                    time     : timestamp,
                    value    : parseInt(res[i]) || 0
                }
            )

            objects.push(
                {
                    counter  : "heartbeat",
                    time     : timestamp,
                    value    : 0
                }
            )
            callback(err, objects)
        )
    )

# ----------------------- INTERNAL ------------------------

perform_on_all_counters = (callback) ->
    redis.smembers("bstats:counters", (err, counters) ->
        counters = counters ?= []
        callback(counters)
    )

send_data = (sockets, channel, message) ->
    sockets.emit(channel, message)

timestamp = () ->
    Math.round(new Date().getTime() / 1000)
