class BstatsCounterLineGraph

    constructor: (params) ->
        @counters        = params.counters || "all"
        @hostname        = params.hostname
        @socket_path     = params.socket_path
        @port            = params.port
        @div_id          = params.div_id
        @data_points     = params.data_points
        @x_tick_count    = params.x_tick_count || 6
        @w               = params.width
        @h               = params.height
        @p_top           = params.padding_top || 25
        @p_right         = params.padding_right || 25
        @p_bottom        = params.padding_bottom || 25
        @p_left          = params.padding_left || 55
        @y_tick_count    = params.y_tick_count || 10
        @duration_time   = params.duration_time || 500
        @update_callback = params.update_callback
        @count           = 0
        @x               = null
        @y               = null
        @counter_data    = {}
        @times           = []
        @xrule_data      = []
        @high_point      = []
        @xrule_period    = Math.round(@data_points/@x_tick_count)
        @dateFormatter   = d3.time.format("%H:%M:%S")
        @format_date     = (timestamp) =>
            date = new Date(timestamp * 1000)
            @dateFormatter(date)

        @path = d3.svg.line()
            .x((d, i) => @x(d.time))
            .y((d) => @y(d.value))
            .interpolate("linear")

        @vis = d3.select(@div_id)
            .append("svg:svg")
            .attr("width", @w)
            .attr("height", @h)
            .append("svg:g")

        socket = io.connect("http://#{@hostname}:#{@port}/#{@socket_path}")

        socket.on('connect', () =>
            console.log("connected to #{@socket_path}")
        )

        socket.on(@socket_path, @process_new_data)

    process_new_data: (new_data) =>
        if @counters == 'all'
            data_to_process = new_data
        else
            data_to_process = new_data.filter((e, i, a) =>
                @counters.some((counter, ei, ea) ->
                    counter == e.counter
                )
            )

        new_data_keys = []
        new_timestamps = {}
        for data in data_to_process
            if !@counter_data[data.counter]
                # populate whole dummy data for new variables
                # is this hacky?
                @counter_data[data.counter] = d3.range(@data_points).map((x) -> {counter:data.counter, time:x,value:0})

            @counter_data[data.counter].shift()
            @counter_data[data.counter].push(
                {
                    counter : data.counter,
                    time    : data.time,
                    value   : data.value
                }
            )
            new_data_keys.push(data.counter)
            new_timestamps[data.time] = data.time

        keys = d3.keys(@counter_data)
        for key in keys
            if new_data_keys.indexOf(key) == -1
                console.log("Removing #{key}")
                delete @counter_data[key]

        d3.keys(new_timestamps).map((timestamp) =>
            @times.push(timestamp)

            @times.shift() if @times.length > @data_points
            @count++
            if @count == @xrule_period
                @xrule_data.push({time:timestamp})
                if @xrule_data.length == (@data_points/@xrule_period) + 1
                    @xrule_data.shift()
                @count = 0
        )

        @calculate_scales()
        @redraw()
        if @update_callback
            @update_callback(data_to_process)


    calculate_scales: () =>
        all_data_objects = d3.merge(d3.values(@counter_data))
        max = d3.max(all_data_objects, (d) -> d.value)

        if max == 0
            ymax = 10
        else
            ymax = max

        highest_current_point = d3.first(all_data_objects.filter((e, i, a) -> e.value == max))
        @high_point.shift()
        @high_point.push(highest_current_point) unless max == 0
        @x = d3.scale.linear().domain([d3.min(@times), d3.max(@times)]).range([0 + @p_left, @w - @p_right])
        @y = d3.scale.linear().domain([0, ymax]).range([@h - @p_bottom, 0 + @p_top])

    redraw: () =>
        xrule = @vis.selectAll("g.x")
            .data(@xrule_data, (d) -> d.time)

        entering_xrule = xrule.enter().append("svg:g")
            .attr("class", "x")

        entering_xrule.append("svg:line")
            .style("shape-rendering", "crispEdges")
            .attr("x1", @w + @p_left)
            .attr("y1", @h - @p_bottom)
            .attr("x2", @w + @p_left)
            .attr("y2", 0 + @p_top)
            .transition()
            .duration(@duration_time)
            .ease("bounce")
            .attr("x1", (d) => @x(d.time))
            .attr("x2", (d) => @x(d.time))

        entering_xrule.append("svg:text")
            .text((d) => @format_date(d.time))
            .style("font-size", "14")
            .attr("text-anchor", "middle")
            .attr("x", @w + @p_left)
            .attr("y", @h - @p_bottom)
            .attr("dy", 15)
            .transition()
            .duration(@duration_time)
            .ease("bounce")
            .attr("x", (d) => @x(d.time))

        xrule.select("line")
            .transition()
            .duration(@duration_time)
            .ease("linear")
            .attr("x1", (d) => @x(d.time))
            .attr("x2", (d) => @x(d.time))

        xrule.select("text")
            .transition()
            .duration(@duration_time)
            .ease("linear")
            .attr("x", (d) => @x(d.time))

        exiting_xrule = xrule.exit()

        exiting_xrule.select("line")
                .transition()
                .duration(@duration_time)
                .ease("linear")
                .delay(@duration_time * 0.8)
                .style("opacity", 0)

        exiting_xrule.select("text")
                .transition()
                .duration(@duration_time * 0.8)
                .ease("linear")
                .delay(@duration_time)
                .style("opacity", 0)

        exiting_xrule.remove()

        yrule = @vis.selectAll("g.y")
            .data(@y.ticks(@y_tick_count))

        entering_yrule = yrule.enter().append("svg:g")
            .attr("class", "y")

        entering_yrule.append("svg:line")
            .style("shape-rendering", "crispEdges")
            .attr("x1", @p_left)
            .attr("y1", 0)
            .attr("x2", @w - @p_right)
            .attr("y2", 0)
            .transition()
            .duration(@duration_time)
            .ease("bounce")
            .attr("y1", @y)
            .attr("y2", @y)

        entering_yrule.append("svg:text")
            .text(@y.tickFormat(@y_tick_count))
            .attr("text-anchor", "end")
            .attr("dx", -5)
            .attr("x", @p_left)
            .attr("y", 0)
            .transition()
            .duration(@duration_time)
            .ease("bounce")
            .attr("y", @y)

        yrule.select("text")
            .transition()
            .duration(@duration_time)
            .attr("y", @y)
            .text(@y.tickFormat(@y_tick_count))

        yrule.select("line")
            .transition()
            .duration(@duration_time)
            .attr("y1", @y)
            .attr("y2", @y)

        exiting_yrule = yrule.exit()

        exiting_yrule.select("line")
                .transition()
                .duration(@duration_time)
                .ease("back")
                .attr("y1", 0)
                .attr("y2", 0)
                .style("opacity", 0)

        exiting_yrule.select("text")
                .transition()
                .duration(@duration_time)
                .ease("back")
                .attr("y", 0)
                .style("opacity", 0)

        exiting_yrule.remove()

        high = @vis.selectAll("g.high_point")
            .data(@high_point, (d) -> d.value)

        entering_high = high.enter()
            .append("svg:g")
            .attr("class","high_point")

        entering_high.append("svg:circle")
            .attr("cx", (d) => @x(d.time))
            .attr("cy", (d) => @y(d.value))
            .attr("class", (d) -> d.counter)
            .attr("r", 4)

        entering_high.append("svg:text")
            .attr("x", (d) => @x(d.time))
            .attr("y", (d) => @y(d.value))
            .attr("text-anchor", "middle")
            .attr("dy", -10)
            .text((d) -> d.value)

        high.select("circle")
            .attr("class", (d) -> d.counter)
            .transition()
            .duration(@duration_time)
            .ease("linear")
            .attr("cx", (d) => @x(d.time))
            .attr("cy", (d) => @y(d.value))

        high.select("text")
            .transition()
            .duration(@duration_time)
            .ease("linear")
            .attr("x", (d) => @x(d.time))
            .attr("y", (d) => @y(d.value))

        exiting_high = high.exit()
        exiting_high.remove()

        paths = @vis.selectAll("path")
            .data(d3.values(@counter_data), (d, i) -> i)

        paths.enter()
            .append("svg:path")
            .attr("d", @path)
            .attr("class", (d) -> d3.first(d).counter)

        paths.attr("transform", "translate(#{@x(@times[5]) - @x(@times[4])})")
            .attr("d", @path)
            .transition()
            .ease("linear")
            .duration(@duration_time)
            .attr("transform", "translate(0)")

        paths.exit()
            .transition()
            .duration(@duration_time)
            .style("opacity", 0)
            .remove()



# ------------- DRAW GRAPHS ------------- #

$.get('/config', (data) ->
    width  = ($(window).width() - 20) * 0.47
    height = $(window).height() * 0.35

    # ------------ LOGINS ----------- #

    login_counters = [
        "facebook_user_login_success",
        "userpass_user_login_success"
    ]

    logins_per_second = new BstatsCounterLineGraph({
        counters     : login_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#logins_per_second"
        data_points  : 300
        socket_path  : 'bstats_counters_per_second'
        width        : width
        height       : height
    })

    logins_per_minute = new BstatsCounterLineGraph({
        counters     : login_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#logins_per_minute"
        data_points  : 60
        socket_path  : 'bstats_counters_per_minute'
        width        : width
        height       : height
    })

    # ------------ VOTES ----------- #
    votes_per_second = new BstatsCounterLineGraph({
        counters     : ["vote_recorded"]
        hostname     : data.hostname
        port         : data.port
        div_id       : "#vote_recorded_per_second"
        data_points  : 300
        socket_path  : 'bstats_counters_per_second'
        width        : width
        height       : height
    })

    votes_per_minute = new BstatsCounterLineGraph({
        counters     : ["vote_recorded"]
        hostname     : data.hostname
        port         : data.port
        div_id       : "#vote_recorded_per_minute"
        data_points  : 60
        socket_path  : 'bstats_counters_per_minute'
        width        : width
        height       : height
        update_callback: (data) ->
            total_votes_in_the_last_hour = d3.sum(@counter_data.vote_recorded.map((d) -> d.value))
            $('#total_votes_in_the_last_hour').text(total_votes_in_the_last_hour)
    })

    # ------------ CREDITS ----------- #
    credit_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]
    credits_per_second = new BstatsCounterLineGraph({
        counters     : credit_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#credits_per_second"
        data_points  : 300
        socket_path  : 'bstats_counters_per_second'
        width        : width
        height       : height
    })

    credits_per_minute = new BstatsCounterLineGraph({
        counters     : credit_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#credits_per_minute"
        data_points  : 60
        socket_path  : 'bstats_counters_per_minute'
        width        : width
        height       : height
    })

    $('#container').isotope({
        itemSelector: '.chart'
        animationEngine: 'best-available'
        filter: '.plasma'
        # masonry: {
        #     columnWidth: Math.round(width)
        # }
    })

    $('#filters a').click(() ->
        selector = $(this).attr('filter')
        $('#filters a').removeClass("selected")
        $(this).addClass("selected")
        $('#container').isotope({ filter: selector })
        false
    )
)
