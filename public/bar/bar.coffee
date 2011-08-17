counter_data = [] # {} or []?
# Slight hack to initialise the array

colors = []
getColor = (name) ->
    if !colors[name]
        colors[name] = Math.floor(Math.random()*16777215).toString(16)
    colors[name]


w = 1000
h = 600
p = 30
x = null
y = null
durationTime = 500
textRotation = 0

socket = io.connect('http://localhost:8888/totals')

socket.on('connect', () ->
    console.log("connected")
)

# counter_data.push({counter:"create_service", value:"3"})
# counter_data.push({counter:"create_organisation", value:"5"})

socket.on('bstat_counter_totals', (new_data) ->
    for data in new_data
        break if data.counter == "no_data"
        elements = counter_data.filter((e, i, a) -> e.counter == data.counter)
        if elements.length == 0
            counter_data.push({
                counter: data.counter
                value : data.value
            })
        else
            element = d3.first(elements)
            element.value = data.value

    calculate_scales()
    redraw()
)


colors = []
getColor = (name) ->
    if !colors[name]
        colors[name] = Math.floor(Math.random()*16777215).toString(16)
    colors[name]

calculate_scales = () ->
    all_data_objects = d3.merge(d3.values(counter_data))
    max = d3.max(all_data_objects, (d) -> d.value)

    if max == 0
        ymax = 10
    else
        ymax = max

    high_point = d3.first(all_data_objects.filter((e, i, a) -> e.value == max))
    x = d3.scale.linear().domain([0, counter_data.length]).range([0 + 2 * p, w - p])
    y = d3.scale.linear().domain([0, ymax]).range([0 + p, h - p])

dateFormatter = d3.time.format("%H:%M:%S")
formatDate = (timestamp) ->
    date = new Date(timestamp * 1000)
    dateFormatter(date)

vis = d3.select("#chart")
    .append("svg:svg")
    .attr("width", w + p)
    .attr("height", h + p)
    # .append("svg:g")
    # .attr("transform", "translate(#{p}, #{p})")


redraw = () ->
    chart = vis.selectAll("g.bars")
            .data(counter_data)

    entering_chart = chart.enter()
                    .append("svg:g")
                    .attr("class", "bars")

    entering_chart.append("svg:rect")
        .attr("x", (d, i) -> x(i))
        .attr("y", (d) -> h - y(d.value))
        .attr("width", w/(counter_data.length + 5) + 1)
        .attr("height", (d) -> y(d.value))
        .attr("fill", (d) -> getColor(d.counter))

    entering_chart.append("svg:text")
        .attr("x", (d, i) -> x(i))
        .attr("y", (d) -> h - y(d.value))
        .attr("dy", 15)
        .attr("dx", -50)
        .attr("transform", (d, i) -> "rotate(#{textRotation} #{x(i) } #{h - y(d.value)})")
        .text((d) -> "#{d.counter} : #{d.value}")

    chart.select("rect")
        .transition()
        .duration(durationTime)
        .ease("bounce")
        .attr("x", (d, i) -> x(i))
        .attr("y", (d) -> h - y(d.value))
        .attr("width", w/(counter_data.length + 5) + 1)
        .attr("height", (d) -> y(d.value))

    chart.select("text")
        # .attr("transform", "rotate(0)")
        .transition()
        .duration(durationTime)
        .ease("bounce")
        .attr("dy", 15)
        .attr("dx", -50)
        .attr("x", (d, i) -> x(i))
        .attr("y", (d) -> h - y(d.value))
        .attr("transform", (d, i) -> "rotate(#{textRotation} #{x(i) } #{h - y(d.value)})")
        .text((d) -> "#{d.counter} : #{d.value}")
