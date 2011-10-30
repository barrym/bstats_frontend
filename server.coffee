config  = require('config')
uuid    = require('node-uuid')
async   = require('async')
express = require('express')
require('express-resource')
_ = require('./public/vendor/underscore-min')

app     = express.createServer()
app.use(express.bodyParser());

# TODO: separate these out so that the main server uses one redis config, and the dashboards have their own host/port details
redis   = require('redis').createClient(config.redis_port, config.redis_server, {})

dashboard = {
    index: (req, res) ->
        key = "bstats:dashboards"
        redis.smembers key, (err, dashboard_ids) ->
            if dashboard_ids.length != 0
                keys = dashboard_ids.map((id) -> "#{key}:#{id}")
                redis.mget keys, (err, dashboards) ->
                    res.send(dashboards.map((d) -> JSON.parse(d)))
            else
                res.send([])

    create: (req, res) ->
        key = "bstats:dashboards"
        dashboard = req.body
        dashboard.id = uuid()
        redis.sadd key, dashboard.id, (err, redis_res) ->
            if err
                res.send({status:"error"}, 400)
            else
                redis.set "#{key}:#{dashboard.id}", JSON.stringify(dashboard), (err, redis_res) ->
                    if err
                    else
                        res.send(dashboard)

    update: (req, res) ->
        key = "bstats:dashboards"
        dashboard = req.body
        dashboard.items.map((item) ->
            if !item.id
                item.id = uuid()
            )
        redis.set "#{key}:#{req.params.dashboard}", JSON.stringify(dashboard), (err, redis_res) ->
            if err

            else
                refresh_dashboard(req.params.dashboard)
                res.send(dashboard)

    destroy: (req, res) ->
        # TODO: add error checking
        console.log("destroying #{req.params.dashboard}")
        key = "bstats:dashboards"
        redis.get "#{key}:#{req.params.dashboard}", (err, dashboard) ->
            if err
                console.log("error with del")
            else
                console.log("removing #{dashboard}")
                redis.srem key, req.params.dashboard, (e, r) ->
                    if e
                        console.log("error with srem")
                    else
                        console.log("sremmed")
                        console.log(r)
                        redis.del "#{key}:#{req.params.dashboard}", (err, result) ->
                            if err
                                console.log("error with del: #{err}")
                                res.send({status:"error"}, 400)
                            else
                                # console.log("destroyed #{dashboard.name}")
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

# TODO: rename apps to namespaces
bstats_app = {
    index: (req, res) ->
        key = "bstats:apps"
        get_namespaces((namespaces) ->
            res.send(namespaces.map((namespace) -> {
                id   : namespace,
                name : namespace
            }))
        )
}

app.resource('dashboards', dashboard, {format:'json'})
app.resource('apps', bstats_app, {format:'json'})

if config.username && config.password
    app.use(express.basicAuth(config.username, config.password))

app.use(express.static("#{__dirname }/public"))
app.listen(config.listen_port)






# --------------- SOCKET.IO CLIENT CODE ------------------

app.get('/config', (req, res) ->
    res.send({
        hostname : config.hostname,
        port     : config.listen_port,
    })
)

io             = require('socket.io').listen(app)
seconds_offset = 3
minutes_offset = 1

get_namespaces = (callback) ->
    redis.smembers "bstats:apps", (err, namespaces) ->
        namespaces = namespaces ?= []
        callback(namespaces)

get_dashboards = (callback) ->
    redis.smembers "bstats:dashboards", (err, dashboards) ->
        dashboards = dashboards ?= []
        callback(dashboards)

get_dashboard = (id, callback) ->
    redis.get "bstats:dashboards:#{id}", (err, dashboard) ->
        callback(JSON.parse(dashboard))

connected_sockets = io.sockets.on('connection', (socket) ->
    console.log("socket client connected")
)

refresh_dashboard = (dashboard_id) ->
    for timestep, dashboards of connected_dashboards
        console.log(dashboards)
        for key, connected_sockets of dashboards
            if key == dashboard_id
                for socket in _.values(connected_sockets)
                    socket.emit('refresh', {})

connected_dashboards = {
        'per_second' : {},
        'per_minute' : {}
    }

io.of('/bstats').on('connection', (socket) ->
    console.log("client connected to /bstats")
    socket.on('dashboard_subscribe', (data) ->
        if data.type == 'counters'
            if !connected_dashboards[data.timestep][data.id]
                connected_dashboards[data.timestep][data.id] = {}
            connected_dashboards[data.timestep][data.id][socket.id] = socket

            if data.timestep == 'per_second'
                init_per_second_counter_objects(socket, data.id, 300)
            else
                init_per_minute_counter_objects(socket, data.id, 60)

            socket.on('disconnect', () ->
                delete connected_dashboards[data.timestep][data.id][socket.id]
                if _.values(connected_dashboards[data.timestep][data.id]).length == 0
                    delete connected_dashboards[data.timestep][data.id]
            )
    )
)

setInterval(
    () ->
        now = timestamp() - seconds_offset
        send_dashboard_updates('per_second', [now])
, 1000)

setInterval(
    () ->
        d = new Date()
        current_minute = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
        now = timestamp_for_date(current_minute) - minutes_offset * 60
        send_dashboard_updates('per_minute', [now])
, 60000)

# --------------- PER SECOND ------------------

init_per_second_counter_objects = (socket, dashboard_id, data_points) ->
    now = timestamp() - seconds_offset
    timestamps = [(now - data_points)...now]
    send_dashboard_counters_to_sockets(dashboard_id, [socket], 'per_second', timestamps)

# --------------- PER MINUTE ------------------

init_per_minute_counter_objects = (socket, dashboard_id, data_points) ->
    d = new Date()
    current_minute = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
    now = timestamp_for_date(current_minute) - minutes_offset * 60
    timestamps = (x for x in [(now - data_points * 60)...now] by 60)

    send_dashboard_counters_to_sockets(dashboard_id, [socket], 'per_minute', timestamps)

# --------------- COUNTERS ---------------------

send_dashboard_updates = (timestep, timestamps) ->
    for dashboard_id, sockets of connected_dashboards[timestep]
        send_dashboard_counters_to_sockets(dashboard_id, _.values(sockets), timestep, timestamps)

send_dashboard_counters_to_sockets = (dashboard_id, sockets, timestep, timestamps) ->
        get_dashboard(dashboard_id, (dashboard) ->
            counters = dashboard.items.map((item) -> item.counters)
            counters = _.flatten(counters)
            counters = _.uniq(counters)

            timestamps_and_counters = timestamps.map((t) ->
                {
                    app       : dashboard.app,
                    timestamp : t,
                    timestep  : timestep
                    counters  : counters
                })
            async.map(timestamps_and_counters, get_counter_objects, (err, results) ->
                flattened_results = _.flatten(results)
                send_data(sockets, timestep, flattened_results) unless flattened_results.length == 0
            )

        )

get_counter_objects = (params, callback) ->
    keys = params.counters.map((counter) -> "bstats:#{params.app}:counter:#{params.timestep}:#{counter}:#{params.timestamp}")

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

send_data = (sockets, channel, data) ->
    # TODO: might not be the most efficient
    for socket in sockets
        socket.emit(channel, data)

timestamp = () ->
    timestamp_for_date(new Date())
timestamp_for_date = (date) ->
    Math.round(date.getTime() / 1000)
