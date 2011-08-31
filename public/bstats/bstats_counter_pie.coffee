class BstatsCounterPie

    constructor: (params) ->
        @counters        = params.counters || "all"
        @hostname        = params.hostname
        @socket_path     = params.socket_path
        @port            = params.port
        @div_id          = params.div_id
        @w               = params.width
        @h               = params.height
        @r               = params.radius
        @p_top           = params.padding_top || 25
        @p_right         = params.padding_right || 25
        @p_bottom        = params.padding_bottom || 25
        @p_left          = params.padding_left || 55
        @data_points     = params.data_points
        @duration_time   = params.duration_time || 500
        @update_callback = params.update_callback
        @title           = params.title || "No title"
        @counter_data    = {}
        @sums            = []

        div = d3.select(@div_id)

        div.append("div")
            .attr("class", "title")
            .text(@title)

        @vis = div.append("svg:svg")
            .attr("width", @w)
            .attr("height", @h)
            .append("svg:g")

        @arc = d3.svg.arc().innerRadius(@r * .5).outerRadius(@r)
        @donut = d3.layout.pie().sort(d3.descending).value((d) -> d.sum)

        socket = io.connect("http://#{@hostname}:#{@port}/#{@socket_path}")

        socket.on('connect', () =>
            console.log("connected to #{@socket_path}")
        )

        socket.on(@socket_path, @process_new_data)

    format: (num) ->
        d3.format(",")(num)

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
        for data in data_to_process
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
            @update_callback(data_to_process)

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

        centre_label.enter()
            .append("svg:g")
            .attr("class", "centre_label")
            .attr("transform", "translate(#{@w/2}, #{@h/2})")
            .append("svg:text")
            .attr("text-anchor", "middle")
            .text((d) => @format(d))

        centre_label.select("text")
            .text((d) => @format(d))



# ------------- DRAW GRAPHS ------------- #

$.get('/config', (data) ->
    width  = ($(window).width() - 20) * 0.47
    height = $(window).height() * 0.35

    # ------------ CREDITS ----------- #
    credit_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]

    new BstatsCounterPie({
        counters     : credit_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#credits_in_the_last_hour_pie"
        data_points  : 60
        socket_path  : 'bstats_counters_per_minute'
        width        : width
        height       : height
        radius       : Math.min(width, height) * 0.4
        title        : "Purchases in the last hour"
    })

)
