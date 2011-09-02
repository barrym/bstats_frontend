$.get('/config', (data) ->
    width  = ($(window).width() - 20) * 0.44
    height = $(window).height() * 0.35

    per_second_height = height * 3/4
    per_second_y_ticks = 5
    per_minute_height = height * 3/4
    per_minute_y_ticks = 4

    # ---- REGISTRATIONS ----- #
    registration_counters = [
        "facebook_user_registration_success",
        "userpass_user_registration_success"
    ]

    registrations_per_second = new BstatsCounterLineGraph({
        counters     : registration_counters
        div_id       : "#registrations_per_second"
        timestep     : 'per_second'
        width        : width
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Registrations"
    })

    registrations_per_minute = new BstatsCounterLineGraph({
        counters     : registration_counters
        div_id       : "#registrations_per_minute"
        timestep     : 'per_minute'
        width        : width
        height       : per_minute_height
        y_tick_count : per_minute_y_ticks
        title        : "Registrations"
    })

    # ------------ LOGINS ----------- #
    login_counters = [
        "facebook_user_login_success",
        "userpass_user_login_success"
    ]

    logins_per_second = new BstatsCounterLineGraph({
        counters     : login_counters
        timestep     : 'per_second'
        div_id       : "#logins_per_second"
        width        : width
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Logins"
    })

    logins_per_minute = new BstatsCounterLineGraph({
        counters     : login_counters
        timestep     : 'per_minute'
        div_id       : "#logins_per_minute"
        width        : width
        height       : per_minute_height
        y_tick_count : per_minute_y_ticks
        title        : "Logins"
    })

    # ------------ VOTES ----------- #
    votes_per_second = new BstatsCounterLineGraph({
        counters     : ["vote_recorded"]
        timestep     : 'per_second'
        div_id       : "#vote_recorded_per_second"
        width        : width
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Votes"
    })

    votes_per_minute = new BstatsCounterLineGraph({
        counters        : ["vote_recorded"]
        timestep     : 'per_minute'
        div_id          : "#vote_recorded_per_minute"
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "Votes"
        update_callback : (data) ->
            total_votes_in_the_last_hour = d3.sum(@counter_data.vote_recorded.map((d) -> d.value))
            $('#total_votes_in_the_last_hour').text(d3.format(",")(total_votes_in_the_last_hour))
    })

    # ------------ PURCHASES ----------- #
    purchase_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]

    purchases_per_second = new BstatsCounterLineGraph({
        counters        : purchase_counters
        timestep     : 'per_second'
        div_id          : "#purchases_per_second"
        width           : width
        height          : per_second_height
        y_tick_count : per_second_y_ticks
        title           : "Purchases"
    })

    purchases_per_minute = new BstatsCounterLineGraph({
        counters        : purchase_counters
        timestep     : 'per_minute'
        div_id          : "#purchases_per_minute"
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "Purchases"
        update_callback : (data) ->
            total_purchases_in_the_last_hour = d3.sum(d3.values(@counter_data).map((values) -> d3.sum(values.map((d) -> d.value))))
            $('#total_purchases_in_the_last_hour').text(d3.format(",")(total_purchases_in_the_last_hour))
    })

    # ------------ MTs ----------- #
    mt_sent_per_second = new BstatsCounterLineGraph({
        counters        : ["mt_sent"]
        timestep     : 'per_second'
        div_id          : "#mt_sent_per_second"
        width           : width
        height          : per_second_height
        y_tick_count : per_second_y_ticks
        title           : "MTs sent"
    })

    mt_sent_per_minute = new BstatsCounterLineGraph({
        counters        : ["mt_sent"]
        timestep     : 'per_minute'
        div_id          : "#mt_sent_per_minute"
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "MTs sent"
    })

    mt_sending_error_per_second = new BstatsCounterLineGraph({
        counters        : ["mt_sending_error"]
        timestep     : 'per_second'
        div_id          : "#mt_sending_error_per_second"
        width           : width
        height          : per_second_height
        y_tick_count : per_second_y_ticks
        title           : "MT sending errors"
    })

    mt_sending_error_per_minute = new BstatsCounterLineGraph({
        counters        : ["mt_sending_error"]
        timestep     : 'per_minute'
        div_id          : "#mt_sending_error_per_minute"
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "MT sending errors"
    })

    # ---- iTunes ----- #
    itunes_request_success_per_second = new BstatsCounterLineGraph({
        counters        : ["itunes_request_success"]
        timestep     : 'per_second'
        div_id          : "#itunes_request_success_per_second"
        width           : width
        height          : per_second_height
        y_tick_count : per_second_y_ticks
        title           : "iTunes success"
    })

    itunes_request_success_per_minute = new BstatsCounterLineGraph({
        counters        : ["itunes_request_success"]
        timestep     : 'per_minute'
        div_id          : "#itunes_request_success_per_minute"
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "iTunes success"
    })

    itunes_request_failed_per_second = new BstatsCounterLineGraph({
        counters        : ["itunes_request_failed"]
        timestep     : 'per_second'
        div_id          : "#itunes_request_failed_per_second"
        width           : width
        height          : per_second_height
        y_tick_count : per_second_y_ticks
        title           : "iTunes failed"
    })

    itunes_request_failed_per_minute = new BstatsCounterLineGraph({
        counters        : ["itunes_request_failed"]
        timestep     : 'per_minute'
        div_id          : "#itunes_request_failed_per_minute"
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "iTunes failed"
    })


    per_second_socket = io.connect("http://#{data.hostname}:#{data.port}/bstats_counters_per_second")

    per_second_socket.on('connect', () =>
        console.log("connected to per_second_socket")
    )

    per_second_socket.on("bstats_counters_per_second", (new_data) ->
        registrations_per_second.process_new_data(new_data)
        logins_per_second.process_new_data(new_data)
        purchases_per_second.process_new_data(new_data)
        votes_per_second.process_new_data(new_data)
        mt_sent_per_second.process_new_data(new_data)
        mt_sending_error_per_second.process_new_data(new_data)
        itunes_request_success_per_second.process_new_data(new_data)
        itunes_request_failed_per_second.process_new_data(new_data)
    )

    per_minute_socket = io.connect("http://#{data.hostname}:#{data.port}/bstats_counters_per_minute")

    per_minute_socket.on('connect', () =>
        console.log("connected to per_minute_socket")
    )

    per_minute_socket.on("bstats_counters_per_minute", (new_data) ->
        registrations_per_minute.process_new_data(new_data)
        logins_per_minute.process_new_data(new_data)
        votes_per_minute.process_new_data(new_data)
        purchases_per_minute.process_new_data(new_data)
        mt_sent_per_minute.process_new_data(new_data)
        mt_sending_error_per_minute.process_new_data(new_data)
        itunes_request_success_per_minute.process_new_data(new_data)
        itunes_request_failed_per_minute.process_new_data(new_data)
    )

    $('#isotopes').isotope({
        itemSelector: '.chart'
        animationEngine: 'best-available'
        # layoutMode: 'straightDown'
        filter: '.per_minute'
        cellsByColumn: {
            columnWidth: Math.round(width/2)
            rowWidth: Math.round(height/2)
        }
    })

    $('#filters a').click(() ->
        selector = $(this).attr('filter')
        $('#filters a').removeClass("selected")
        $(this).addClass("selected")
        $('#isotopes').isotope({ filter: selector })
        false
    )
)
