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

setInterval(
    () ->
        now = timestamp() - seconds_offset
        send_counter_objects_for_timestamp(per_second_sockets, [now])
, 1000)

setInterval(
    () ->
        console.log(minute_timestamp())
, 60000)

# --------------- PER SECOND ------------------

init_per_second_objects = (sockets, data_points) ->
    now = timestamp() - seconds_offset
    timestamps = [(now - data_points)...now]
    send_counter_objects_for_timestamp(sockets, timestamps)

# --------------- GENERAL ---------------------

send_counter_objects_for_timestamp = (sockets, timestamps) ->
    if config.counters == 'all'
        get_all_counters((counters) ->
            send_counter_objects(sockets, timestamps, counters)
        )
    else
        send_counter_objects(sockets, timestamps, config.counters)

send_counter_objects = (sockets, timestamps, counters) ->
    timestamps_and_counters = timestamps.map((t) -> {timestamp:t, counters:counters})
    async.map(timestamps_and_counters, get_counter_objects, (err, results) ->
        flattened_results = results.reduce((a, b) ->
            a.concat(b)
        )
        send_data(sockets, 'bstats_counters_per_second', flattened_results) unless flattened_results.length == 0
    )

get_counter_objects = (params, callback) ->
    keys = params.counters.map((counter) -> "bstats:counter:#{counter}:#{params.timestamp}")

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
    Math.round(new Date().getTime() / 1000)

minute_timestamp = () ->
    date = new Date()
    "#{date.getFullYear()}#{zero_pad(date.getMonth() + 1)}#{zero_pad(date.getDate())}#{zero_pad(date.getHours())}#{zero_pad(date.getMinutes())}"

zero_pad = (number) ->
    if number.toString().length == 2
        number
    else
        '0' + number
