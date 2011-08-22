config  = require('config')
async   = require('async')
express = require('express')
app     = express.createServer()
app.use(express.static("#{__dirname }/public"))
app.listen(config.listen_port)

io             = require('socket.io').listen(app)
redis          = require('redis').createClient(config.redis_port, config.redis_server, {})
seconds_offset = 2

connected_sockets = io.sockets.on('connection', (socket) ->
    console.log("socket client connected")
)

per_second_sockets = io.of('/bstats_counters_per_second').on('connection', (socket) ->
    console.log("per second client connected")
    init_per_second_objects(socket, 300)
)

per_minute_sockets = io.of('/bstats_counters_per_minute').on('connection', (socket) ->
    console.log("per minute client connected")
    init_per_minute_objects(socket, 60)
)

setInterval(
    () ->
        now = timestamp() - seconds_offset
        send_counter_objects_for_timestamp(per_second_sockets, [now], 'bstats_counters_per_second')
, 1000)

setInterval(
    () ->
        d = new Date()
        current_minute = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
        now = timestamp_for_date(current_minute)
        send_counter_objects_for_timestamp(per_minute_sockets, [now], 'bstats_counters_per_minute')
, 60000)

# --------------- PER SECOND ------------------

init_per_second_objects = (sockets, data_points) ->
    now = timestamp() - seconds_offset
    timestamps = [(now - data_points)...now]
    send_counter_objects_for_timestamp(sockets, timestamps, 'bstats_counters_per_second')

# --------------- PER MINUTE ------------------

init_per_minute_objects = (sockets, data_points) ->
    d = new Date()
    current_minute = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
    now = timestamp_for_date(current_minute)
    timestamps = (x for x in [(now - data_points * 60)...now] by 60)

    send_counter_objects_for_timestamp(sockets, timestamps, 'bstats_counters_per_minute')

# --------------- GENERAL ---------------------

send_counter_objects_for_timestamp = (sockets, timestamps, channel) ->
    if config.counters == 'all'
        get_all_counters((counters) ->
            send_counter_objects(sockets, timestamps, channel, counters)
        )
    else
        send_counter_objects(sockets, timestamps, channel, config.counters)

send_counter_objects = (sockets, timestamps, channel, counters) ->
    timestamps_and_counters = timestamps.map((t) ->
        {
            timestamp : t,
            timestep : if channel == "bstats_counters_per_second" then "per_second" else "per_minute",
            counters : counters
        })
    async.map(timestamps_and_counters, get_counter_objects, (err, results) ->
        flattened_results = results.reduce((a, b) ->
            a.concat(b)
        )
        send_data(sockets, channel, flattened_results) unless flattened_results.length == 0
    )

get_counter_objects = (params, callback) ->
    keys = params.counters.map((counter) -> "bstats:counter:#{params.timestep}:#{counter}:#{params.timestamp}")

    redis.mget(keys, (err, res) ->
        objects = params.counters.map((counter, i) ->
            {
                counter  : counter,
                time     : params.timestamp,
                value    : parseInt(res[i]) || 0
            }
        )

        callback(err, objects)
    )

# ----------------------- INTERNAL ------------------------

get_all_counters = (callback) ->
    redis.smembers("bstats:counters", (err, counters) ->
        counters = counters ?= []
        callback(counters)
    )

send_data = (sockets, channel, data) ->
    sockets.emit(channel, data)

timestamp = () ->
    timestamp_for_date(new Date())
timestamp_for_date = (date) ->
    Math.round(date.getTime() / 1000)
