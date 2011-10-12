$.get('/config', (data) ->
    width  = ($(window).width() - 20) * 0.44
    height = $(window).height() * 0.35

    large_height = height * 0.8
    large_y_ticks = 5
    small_height = height * 0.5
    small_y_ticks = 2

    operators = [
        "uk_o2",
        "uk_orange",
        "uk_vodafone",
        "uk_tmobile",
        "uk_three"
        # "ie_three",
        # "ie_meteor",
        # "ie_vodafone",
        # "ie_o2",
        # "ipx",
        # "reach_data"
    ]

    mt_sent_counters = ("mt_sent_#{operator}" for operator in operators)
    mt_sent_per_minute = new BstatsCounterLineGraph({
        counters        : mt_sent_counters
        div_id          : "#mt_sent_per_minute"
        timestep        : 'per_minute'
        width           : width
        height          : large_height
        y_tick_count    : large_y_ticks
        title           : "MTs sent"
        update_callback : (data) ->
            total_mts_in_the_last_hour = d3.sum(d3.values(@counter_data).map((values) -> d3.sum(values.map((d) -> d.value))))
            $('#total_mts_in_the_last_hour').text(d3.format(",")(total_mts_in_the_last_hour))
    })

    dr_request_received_counters = ("dr_request_received_#{operator}" for operator in operators)
    dr_request_received_per_minute = new BstatsCounterLineGraph({
        counters        : dr_request_received_counters
        div_id          : "#dr_request_received_per_minute"
        timestep        : 'per_minute'
        width           : width
        height          : large_height
        y_tick_count    : large_y_ticks
        title           : "DRs received"
        update_callback : (data) ->
            total_drs_in_the_last_hour = d3.sum(d3.values(@counter_data).map((values) -> d3.sum(values.map((d) -> d.value))))
            $('#total_drs_in_the_last_hour').text(d3.format(",")(total_drs_in_the_last_hour))
    })

    mo_request_received_counters = ("mo_request_received_#{operator}" for operator in operators)
    mo_request_received_per_minute = new BstatsCounterLineGraph({
        counters        : mo_request_received_counters
        div_id          : "#mo_request_received_per_minute"
        timestep        : 'per_minute'
        width           : width
        height          : large_height
        y_tick_count    : large_y_ticks
        title           : "MOs received"
        update_callback : (data) ->
            total_mos_in_the_last_hour = d3.sum(d3.values(@counter_data).map((values) -> d3.sum(values.map((d) -> d.value))))
            $('#total_mos_in_the_last_hour').text(d3.format(",")(total_mos_in_the_last_hour))
    })

    mt_sending_error_counters = ("mt_sending_error_#{operator}" for operator in operators)
    mt_sending_error_per_minute = new BstatsCounterLineGraph({
        counters     : mt_sending_error_counters
        div_id       : "#mt_sending_error_per_minute"
        timestep     : 'per_minute'
        width        : width
        height       : small_height
        y_tick_count : small_y_ticks
        title        : "MT sending errors"
    })

    failed_to_send_mt_counters = ("failed_to_send_mt_#{operator}" for operator in operators)
    failed_to_send_mt_per_minute = new BstatsCounterLineGraph({
        counters     : failed_to_send_mt_counters
        div_id       : "#failed_to_send_mt_per_minute"
        timestep     : 'per_minute'
        width        : width
        height       : small_height
        y_tick_count : small_y_ticks
        title        : "Failed to send MT"
    })

    per_minute_socket = io.connect("http://#{data.hostname}:#{data.port}/bstats_counters_per_minute")

    per_minute_socket.on('connect', () =>
        console.log("connected to per_minute_socket")
    )

    per_minute_socket.on("bstats_counters_per_minute", (new_data) ->
        mt_sent_per_minute.process_new_data(new_data)
        dr_request_received_per_minute.process_new_data(new_data)
        mo_request_received_per_minute.process_new_data(new_data)
        mt_sending_error_per_minute.process_new_data(new_data)
        failed_to_send_mt_per_minute.process_new_data(new_data)
    )
)
