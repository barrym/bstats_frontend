count = 0
high_point = null
xrule_data = []
xrulePeriod = 60 # seconds
data_points = 300

counter_data = [] # {} or []?
# Slight hack to initialise the array
['no_data'].map((counter) ->
    counter_data[counter] = d3.range(data_points).map((x) -> {counter:counter,time:x,value:1})
)

colors = []
getColor = (name) ->
    if !colors[name]
        colors[name] = Math.floor(Math.random()*16777215).toString(16)
    colors[name]


w = 610
h = 380
p = 30
durationTime = 500
x = null
y = null
yTickCount = 15

times = d3.first(d3.values(counter_data)).map((d) -> d.time)

socket = io.connect("http://localhost:8888/per_second")

socket.on('connect', () ->
    console.log("connected")
)

socket.on('bstat_counters', (new_data) ->
    new_data_keys = []
    for data in new_data
        if !counter_data[data.counter]
            # is this hacky?
            counter_data[data.counter] = d3.range(data_points).map((x) -> {counter:data.counter,time:x,value:1})

        counter_data[data.counter].shift()
        counter_data[data.counter].push(
            {
                counter:data.counter,
                time:data.time,
                value:data.value
            }
        )
        new_data_keys.push(data.counter)

    keys = d3.keys(counter_data)
    for key in keys
        if new_data_keys.indexOf(key) == -1
            console.log("Removing #{key}")
            delete counter_data[key]

    latest_timestamp = d3.last(d3.first(d3.values(counter_data))).time
    times.push(latest_timestamp)
    times.shift()

    count++
    if count == xrulePeriod
        xrule_data.push({time:latest_timestamp})
        if xrule_data.length == (data_points/xrulePeriod) + 1 # On first load it might not have 3 elements
            xrule_data.shift()
        count = 0

    calculate_scales()
    redraw()
)

calculate_scales = () ->
    all_data_objects = d3.merge(d3.values(counter_data))
    max = d3.max(all_data_objects, (d) -> d.value)

    if max == 0
        ymax = 10
    else
        ymax = max

    high_point = d3.first(all_data_objects.filter((e, i, a) -> e.value == max))
    x = d3.scale.linear().domain([d3.min(times), d3.max(times)]).range([0 + 2 * p, w - p])
    y = d3.scale.linear().domain([0, ymax]).range([h - p, 0 + p])

dateFormatter = d3.time.format("%H:%M:%S")
formatDate = (timestamp) ->
    date = new Date(timestamp * 1000)
    dateFormatter(date)

vis = d3.select("#per_second")
    .append("svg:svg")
    .attr("width", w + p) # To make room for the labels
    .attr("height", h + p)
    .append("svg:g")
    .attr("transform", "translate(#{p}, #{p})")

path = d3.svg.line()
    .x((d, i) -> x(d.time))
    .y((d) -> y(d.value))
    .interpolate("linear")

redraw = () ->
    paths = vis.selectAll("path")
        .data(d3.values(counter_data), (d, i) -> i)

    paths.enter()
        .append("svg:path")
        .attr("d", path)
        .attr("class", (d) -> d3.first(d).counter)
        .style("stroke", (d) -> getColor(d3.first(d).counter))

    paths.attr("transform", "translate(#{x(times[5]) - x(times[4])})")
        .attr("d", path)
        .transition()
        .ease("linear")
        .duration(durationTime)
        .attr("transform", "translate(0)")

    paths.exit()
        .transition()
        .duration(durationTime)
        .style("opacity", 0)
        .remove()

    xrule = vis.selectAll("g.x")
        .data(xrule_data, (d) -> d.time)

    entering_xrule = xrule.enter().append("svg:g")
        .attr("class", "x")

    entering_xrule.append("svg:line")
        .style("shape-rendering", "crispEdges")
        .attr("x1", w + p)
        .attr("y1", h - p)
        .attr("x2", w + p)
        .attr("y2", 0)
        .transition()
        .duration(durationTime)
        .ease("bounce")
        .attr("x1", (d) -> x(d.time))
        .attr("x2", (d) -> x(d.time))

    entering_xrule.append("svg:text")
        .text((d) -> formatDate(d.time))
        .style("font-size", "14")
        .attr("text-anchor", "middle")
        .attr("x", w + p)
        .attr("y", h - p)
        .attr("dy", 15)
        .transition()
        .duration(durationTime)
        .ease("bounce")
        .attr("x", (d) -> x(d.time))

    xrule.select("line")
        .transition()
        .duration(durationTime)
        .ease("linear")
        .attr("x1", (d) -> x(d.time))
        .attr("x2", (d) -> x(d.time))

    xrule.select("text")
        .transition()
        .duration(durationTime)
        .ease("linear")
        .attr("x", (d) -> x(d.time))

    exiting_xrule = xrule.exit()

    exiting_xrule.select("line")
            .transition()
            .duration(durationTime)
            .ease("linear")
            .delay(durationTime * 0.8)
            .style("opacity", 0)

    exiting_xrule.select("text")
            .transition()
            .duration(durationTime * 0.8)
            .ease("linear")
            .delay(durationTime)
            .style("opacity", 0)

    exiting_xrule.remove()

    yrule = vis.selectAll("g.y")
        .data(y.ticks(yTickCount))

    entering_yrule = yrule.enter().append("svg:g")
        .attr("class", "y")

    entering_yrule.append("svg:line")
        .style("shape-rendering", "crispEdges")
        .attr("x1", p)
        .attr("y1", 0)
        .attr("x2", w)
        .attr("y2", 0)
        .transition()
        .duration(durationTime)
        .ease("bounce")
        .attr("y1", y)
        .attr("y2", y)

    entering_yrule.append("svg:text")
        .text(y.tickFormat(yTickCount))
        .attr("text-anchor", "end")
        .attr("dx", -5)
        .attr("x", p)
        .attr("y", 0)
        .transition()
        .duration(durationTime)
        .ease("bounce")
        .attr("y", y)

    yrule.select("text")
        .transition()
        .duration(durationTime)
        .attr("y", y)
        .text(y.tickFormat(yTickCount))

    yrule.select("line")
        .transition()
        .duration(durationTime)
        .attr("y1", y)
        .attr("y2", y)

    exiting_yrule = yrule.exit()

    exiting_yrule.select("line")
            .transition()
            .duration(durationTime)
            .ease("back")
            .attr("y1", 0)
            .attr("y2", 0)
            .style("opacity", 0)

    exiting_yrule.select("text")
            .transition()
            .duration(durationTime)
            .ease("back")
            .attr("y", 0)
            .style("opacity", 0)

    exiting_yrule.remove()

    legends = vis.selectAll("g.legend")
        .data(d3.keys(counter_data), (d,i) -> i)

    entering_legends = legends.enter().append("svg:g")
        .attr("class", "legend")

    entering_legends.append("svg:rect")
        .attr("x", w + 10)
        .attr("y", (d, i) -> (i * 20))
        .attr("height", 10)
        .attr("width", 10)
        .style("stroke", (d) -> getColor(d))
        .style("fill", (d) -> getColor(d))

    entering_legends.append("svg:text")
        .attr("x", w + 10)
        .attr("y", (d, i) -> (i * 20))
        .attr("dx", 20)
        .attr("dy", 8)
        .text(String)

    legends.select("rect")
        .style("stroke", (d) -> getColor(d))
        .style("fill", (d) -> getColor(d))

    legends.select("text")
        .text(String)

    exiting_legends = legends.exit()

    exiting_legends.select("rect")
        .transition()
        .duration(durationTime)
        .style("opacity", 0)

    exiting_legends.select("text")
        .transition()
        .duration(durationTime)
        .style("opacity", 0)

    exiting_legends.remove()

    high = vis.selectAll("g.high_point")
        .data([high_point])

    entering_high = high.enter()
        .append("svg:g")
        .attr("class","high_point")

    entering_high.append("svg:circle")
        .attr("cx", (d) -> x(d.time))
        .attr("cy", (d) -> y(d.value))
        .attr("class", (d) -> d.counter)
        .attr("r", 4)

    entering_high.append("svg:text")
        .attr("x", (d) -> x(d.time))
        .attr("y", (d) -> y(d.value))
        .attr("text-anchor", "middle")
        .attr("dy", -10)
        .text((d) -> d.value)

    high.select("circle")
        .attr("class", (d) -> d.counter)
        .transition()
        .duration(durationTime)
        .ease("linear")
        .attr("cx", (d) -> x(d.time))
        .attr("cy", (d) -> y(d.value))

    high.select("text")
        .text((d) -> d.value)
        .transition()
        .duration(durationTime)
        .ease("linear")
        .attr("x", (d) -> x(d.time))
        .attr("y", (d) -> y(d.value))

