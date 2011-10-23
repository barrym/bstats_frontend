config  = require('config')
async   = require('async')
express = require('express')
require('express-resource')
app     = express.createServer()
app.use(express.bodyParser());
# TODO: separate these out so that the main server uses one redis config, and the dashboards have their own host/port details
redis   = require('redis').createClient(config.redis_port, config.redis_server, {})

dashboard = {
    index: (req, res) ->
        key = "bstats:dashboards"
        redis.smembers key, (err, dashboards) ->
            res.send(dashboards.map((d) -> JSON.parse(d)))

    create: (req, res) ->
        key = "bstats:dashboards"
        dashboard = req.body
        dashboard.id = guid()
        redis.sadd key, JSON.stringify(dashboard), (err, redis_res) ->
            if err
                res.send({status:"error"}, 400)
            else
                redis.set "#{key}:#{dashboard.id}", JSON.stringify(dashboard), (err, redis_res) ->
                    if err
                    else
                        res.send(dashboard)

    destroy: (req, res) ->
        # TODO: add error checking
        key = "bstats:dashboards"
        redis.get "#{key}:#{req.params.dashboard}", (err, dashboard) ->
            redis.srem key, dashboard, (e, r) ->
                redis.del "#{key}:#{req.params.dashboard}", (err, result) ->
                    res.send(JSON.parse(dashboard))

    show: (req, res) ->
        key = "bstats:dashboards"
        redis.get "#{key}:#{req.params.dashboard}", (err, dashboard) ->
            if err
                res.send({status:"error"}, 400)
            else
                dashboard = JSON.parse(dashboard)
                redis.smembers "bstats:#{dashboard.app}:counters", (err, counters) ->
                    dashboard.counters = counters.sort()
                    res.send(dashboard)


    }

bstats_app = {
    index: (req, res) ->
        key = "bstats:apps"
        redis.smembers key, (err, apps) ->
            res.send(apps.map((app) -> {
                id:app,
                name:app
            }))
}

app.resource('dashboards', dashboard, {format:'json'})
app.resource('apps', bstats_app, {format:'json'})

if config.username && config.password
    app.use(express.basicAuth(config.username, config.password))

app.use(express.static("#{__dirname }/public"))
app.listen(config.listen_port)






# --------------- SOCKET.IO CLIENT CODE ------------------

app.get('/config', (req, res) ->
    res.send({hostname:config.hostname, port:config.listen_port})
)

io             = require('socket.io').listen(app)
# redis          = require('redis').createClient(config.redis_port, config.redis_server, {})
seconds_offset = 3
minutes_offset = 1

connected_sockets = io.sockets.on('connection', (socket) ->
    console.log("socket client connected")
)

counters_per_second_sockets = io.of('/bstats_counters_per_second').on('connection', (socket) ->
    console.log("counters per second client connected")
    init_per_second_counter_objects(socket, 300)
)

counters_per_minute_sockets = io.of('/bstats_counters_per_minute').on('connection', (socket) ->
    console.log("counters per minute client connected")
    init_per_minute_counter_objects(socket, 60)
)

gauges_per_second_sockets = io.of('/bstats_gauges_per_second').on('connection', (socket) ->
    console.log("gauges per second client connected")
    init_per_second_gauge_objects(socket, 300)
)

setInterval(
    () ->
        now = timestamp() - seconds_offset
        send_counter_objects_for_timestamp(counters_per_second_sockets, [now], 'bstats_counters_per_second')
        send_gauge_objects_for_timestamp(gauges_per_second_sockets, [now], 'bstats_gauges_per_second')
, 1000)

setInterval(
    () ->
        d = new Date()
        current_minute = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
        now = timestamp_for_date(current_minute) - minutes_offset * 60
        send_counter_objects_for_timestamp(counters_per_minute_sockets, [now], 'bstats_counters_per_minute')
, 60000)

# --------------- PER SECOND ------------------

init_per_second_counter_objects = (sockets, data_points) ->
    now = timestamp() - seconds_offset
    timestamps = [(now - data_points)...now]
    send_counter_objects_for_timestamp(sockets, timestamps, 'bstats_counters_per_second')

init_per_second_gauge_objects = (sockets, data_points) ->
    now = timestamp() - seconds_offset
    timestamps = [(now - data_points)...now]
    send_gauge_objects_for_timestamp(sockets, timestamps, 'bstats_gauges_per_second')

# --------------- PER MINUTE ------------------

init_per_minute_counter_objects = (sockets, data_points) ->
    d = new Date()
    current_minute = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
    now = timestamp_for_date(current_minute) - minutes_offset * 60
    timestamps = (x for x in [(now - data_points * 60)...now] by 60)

    send_counter_objects_for_timestamp(sockets, timestamps, 'bstats_counters_per_minute')

# --------------- COUNTERS ---------------------

send_counter_objects_for_timestamp = (sockets, timestamps, channel) ->
    if config.counters == 'all'
        get_all_counters((counters) ->
            send_counter_objects(sockets, timestamps, channel, counters)
        )
    else
        send_counter_objects(sockets, timestamps, channel, config.counters)

get_all_counters = (callback) ->
    redis.smembers("bstats:counters", (err, counters) ->
        counters = counters ?= []
        callback(counters)
    )

send_counter_objects = (sockets, timestamps, channel, counters) ->
    timestamps_and_counters = timestamps.map((t) ->
        {
            timestamp : t,
            timestep  : if channel == "bstats_counters_per_second" then "per_second" else "per_minute",
            counters  : counters
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

# --------------- GAUGES ---------------------

send_gauge_objects_for_timestamp = (sockets, timestamps, channel) ->
    if config.gauges == 'all'
        get_all_gauges((gauges) ->
            send_gauge_objects(sockets, timestamps, channel, gauges)
        )
    else
        send_gauge_objects(sockets, timestamps, channel, config.gauges)

get_all_gauges = (callback) ->
    redis.smembers("bstats:gauges", (err, gauges) ->
        gauges = gauges ?= []
        callback(gauges)
    )

send_gauge_objects = (sockets, timestamps, channel, gauges) ->
    timestamps_and_gauges = timestamps.map((t) ->
        {
            timestamp : t,
            timestep  : if channel == "bstats_gauges_per_second" then "per_second" else "per_minute",
            gauges    : gauges
        })
    async.map(timestamps_and_gauges, get_gauge_objects, (err, results) ->
        flattened_results = flatten_array(results)
        send_data(sockets, channel, flattened_results) unless flattened_results.length == 0
    )

get_gauge_objects = (params, final_callback) ->
    async.map(params.gauges, (gauge, map_callback) ->
        async.series([
            (callback) ->
                key = "bstats:gauge:#{params.timestep}:#{gauge}:sum:#{params.timestamp}"
                redis.get(key, (err, res) ->
                    sum = parseInt(res)/1000
                    callback(null, sum)
                )
            ,
            (callback) ->
                key = "bstats:gauge:#{params.timestep}:#{gauge}:count:#{params.timestamp}"
                redis.get(key, (err, res) ->
                    count = parseInt(res)
                    callback(null, count)
                )
            ,
            (callback) ->
                key = "bstats:gauge:#{params.timestep}:#{gauge}:max:#{params.timestamp}"
                redis.zrange(key, 0, 0, (err, res) ->
                    max =  parseInt(res)/1000
                    callback(null, max)
                )
            ,
            (callback) ->
                key = "bstats:gauge:#{params.timestep}:#{gauge}:min:#{params.timestamp}"
                redis.zrange(key, 0, 0, (err, res) ->
                    min = parseInt(res)/1000
                    callback(null, min)
                )
        ], (err, results) ->
            avg = results[0]/results[1]
            object = {
                gauge     : gauge,
                timestamp : params.timestamp,
                max       : results[2] || 0,
                min       : results[3] || 0,
                avg       : avg || 0
            }
            map_callback(null, object)
        )
    , (err, results) ->
        final_callback(null, results)
    )

# ----------------------- INTERNAL ------------------------

flatten_array = (array) ->
    array.reduce((a, b) ->
        a.concat(b)
    )

send_data = (sockets, channel, data) ->
    sockets.emit(channel, data)

timestamp = () ->
    timestamp_for_date(new Date())
timestamp_for_date = (date) ->
    Math.round(date.getTime() / 1000)

guid = () ->
    S4 = () ->
       (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())
