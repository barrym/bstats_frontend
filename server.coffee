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

totals_sockets = io.of('/totals').on('connection', (socket) ->
    console.log("totals client connected")
    init_totals_data(socket)
)

per_second_sockets = io.of('/per_second').on('connection', (socket) ->
    console.log("per second client connected")
    init_per_second_data(socket, 300)
)

setInterval(
    () ->
        now = timestamp() - offset
        send_per_second_data(per_second_sockets, [now])
        send_totals_data(totals_sockets)
, 1000)


# --------------- PER SECOND ------------------ #
init_per_second_data = (socket, data_points) ->
    now = timestamp() - offset
    timestamps = [(now - data_points)...now]
    send_per_second_data(socket, timestamps)

send_per_second_data = (sockets, timestamps) ->
    get_per_second_data_for_timestamps(timestamps, [], (final_result) ->
        flattened_results = final_result.reduce((a, b) ->
            a.concat(b)
        )
        send_data(sockets, 'bstat_counters', flattened_results)
    )

get_per_second_data_for_timestamps = (timestamps, acc, return_fun) ->
    if timestamps.length == 0
        return_fun(acc)
    else
        now = timestamps.shift()
        perform_on_all_counters((counters) ->
            keys = counters.map((counter) -> "bstats:counter:#{counter}:#{now}")

            redis.mget(keys, (err, res) ->
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
                acc.push(message)
                get_per_second_data_for_timestamps(timestamps, acc, return_fun)
            )
        )

 # ------------------- TOTALS ------------------------------
init_totals_data = (socket) ->
    send_totals_data(socket)

send_totals_data = (sockets) ->
    perform_on_all_counters((counters) ->
        keys = counters.map((counter) -> "bstats:counter:#{counter}:total")

        redis.mget(keys, (err, res) ->
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

            send_data(sockets, 'bstat_counter_totals', message)
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
