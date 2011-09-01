class BstatsBase

    constructor: (params) ->
        @counters        = params.counters || "all"
        @socket_url      = params.socket_url
        @div_id          = params.div_id
        @w               = params.width
        @h               = params.height
        @p_top           = params.padding_top || 25
        @p_right         = params.padding_right || 25
        @p_bottom        = params.padding_bottom || 25
        @p_left          = params.padding_left || 65
        @data_points     = params.data_points
        @duration_time   = params.duration_time || 500
        @update_callback = params.update_callback
        @title           = params.title
        @counter_data    = {}
        @dateFormatter   = d3.time.format("%H:%M:%S")

        div = d3.select(@div_id)

        if @title
            div.append("div")
                .attr("class", "title")
                .text(@title)

        @vis = div.append("svg:svg")
            .attr("width", @w)
            .attr("height", @h)
            .append("svg:g")

        if @socket_url
            socket = io.connect(@socket_url)

            socket.on('connect', () =>
                console.log("connected to #{@socket_url}")
            )

            socket.on('new_data', @process_new_data)

    format: (num) ->
        d3.format(",")(num)

    format_timestamp: (timestamp) =>
        date = new Date(timestamp * 1000)
        @dateFormatter(date)

    process_new_data: (new_data) =>
        # Filter out counters we're not interested in
        if @counters == 'all'
            @data_to_process = new_data
        else
            @data_to_process = new_data.filter((e, i, a) =>
                @counters.some((counter, ei, ea) ->
                    counter == e.counter
                )
            )
        new_data = null

class BstatsCounterPie extends BstatsBase

    constructor: (params) ->
        super params
        @r               = params.radius
        @inner_title     = params.inner_title
        @sums            = []
        @arc = d3.svg.arc().innerRadius(@r * .5).outerRadius(@r)
        @donut = d3.layout.pie().sort(d3.descending).value((d) -> d.sum)

    process_new_data: (new_data) =>
        super new_data

        new_data_keys = []
        for data in @data_to_process
            if !@counter_data[data.counter]
                @counter_data[data.counter] = d3.range(@data_points).map((x) -> 0)

            @counter_data[data.counter].shift()
            @counter_data[data.counter].push(data.value)
            new_data_keys.push(data.counter)

        keys = d3.keys(@counter_data)
        for key in keys
            if new_data_keys.indexOf(key) == -1
                console.log("Removing #{key}")
                delete @counter_data[key]

        for entries in d3.entries(@counter_data)
            sum = d3.sum(entries.value)
            if sum == 0
                delete @sums[entries.key]
            else
                @sums[entries.key] = {
                        counter: entries.key
                        sum: sum
                }

        @redraw()
        if @update_callback
            @update_callback(@data_to_process)

    redraw: () =>
        arcs = @vis.selectAll("g.arc")
                .data(@donut(d3.values(@sums)))

        entering_arcs = arcs.enter()
            .append("svg:g")
            .attr("class", "arc")
            .attr('fill-rule', 'evenodd')
            .attr("transform", "translate(#{@w/2}, #{@h/2})")

        entering_arcs.append("svg:path")
            .attr('d', (d) => @arc(d))
            .attr('class', (d) -> d.data.counter)

        entering_arcs.append("svg:text")
            .attr('transform', (d) => "translate(#{@arc.centroid(d)})")
            .attr('text-anchor', 'middle')
            .attr('dy', '.35em')
            .text((d) => @format(d.value))

        arcs.select("path")
            .transition()
            .ease("bounce")
            .duration(500)
            .attr('d', (d) => @arc(d))

        arcs.select("text")
            .attr('transform', (d) => "translate(#{@arc.centroid(d)})")
            .attr('text-anchor', 'middle')
            .attr('dy', '.35em')
            .text((d) => @format(d.value))

        centre_label = @vis.selectAll("g.centre_label")
            .data([d3.sum(d3.values(@sums), (d) -> d.sum)])

        new_label = centre_label.enter()
            .append("svg:g")
            .attr("class", "centre_label")
            .attr("transform", "translate(#{@w/2}, #{@h/2})")

        if @inner_title
            new_label.append("svg:text")
                .attr("class", "number")
                .attr('dy', -10)
                .attr("text-anchor", "middle")
                .text((d) => @format(d))

            new_label.append("svg:text")
                .attr('dy', 10)
                .attr("text-anchor", "middle")
                .attr("class", "inner_title")
                .text(@inner_title)
        else
            new_label.append("svg:text")
                .attr("class", "number")
                .attr("text-anchor", "middle")
                .text((d) => @format(d))

        centre_label.select("text.number")
            .text((d) => @format(d))

class BstatsCounterLineGraph extends BstatsBase

    constructor: (params) ->
        super params
        @x_tick_count    = params.x_tick_count || 6
        @y_tick_count    = params.y_tick_count || 10
        @count           = 0
        @x               = null
        @y               = null
        @times           = []
        @xrule_data      = []
        @high_point      = []
        @xrule_period    = Math.round(@data_points/@x_tick_count)

        @path = d3.svg.line()
            .x((d, i) => @x(d.time))
            .y((d) => @y(d.value))
            .interpolate("linear")

    process_new_data: (new_data) =>
        super new_data

        new_data_keys = []
        new_timestamps = {}
        for data in @data_to_process
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

        keys = null

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

        new_data_keys = null
        new_timestamps = null

        @calculate_scales()
        @redraw()
        if @update_callback
            @update_callback(@data_to_process)

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
            .text((d) => @format_timestamp(d.time))
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
            .attr("r", 3)

        entering_high.append("svg:text")
            .attr("x", (d) => @x(d.time))
            .attr("y", (d) => @y(d.value))
            .attr("text-anchor", "middle")
            .attr("dy", -10)
            .text((d) => @format(d.value))

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
