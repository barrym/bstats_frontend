$.get('/config', (data) ->
    width  = ($(window).width() - 20) * 0.47
    height = $(window).height() * 0.35

    per_second_height = height * 3/4
    per_second_y_ticks = 5
    per_minute_height = height/2
    per_minute_y_ticks = 3

    # --- LINE CHARTS --- #

    # ---- REGISTRATIONS ----- #
    registration_counters = [
        "facebook_user_registration_success",
        "userpass_user_registration_success"
    ]

    registrations_per_minute = new BstatsCounterLineGraph({
        counters     : registration_counters
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_minute"
        div_id       : "#registrations_per_minute"
        data_points  : 60
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

    logins_per_minute = new BstatsCounterLineGraph({
        counters     : login_counters
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_minute"
        div_id       : "#logins_per_minute"
        data_points  : 60
        width        : width
        height       : per_minute_height
        y_tick_count : per_minute_y_ticks
        title        : "Logins"
    })

    # ------------ VOTES ----------- #
    votes_per_second = new BstatsCounterLineGraph({
        counters     : ["vote_recorded"]
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_second"
        div_id       : "#vote_recorded_per_second"
        data_points  : 300
        width        : width
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Votes"
    })

    votes_per_minute = new BstatsCounterLineGraph({
        counters        : ["vote_recorded"]
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_minute"
        div_id          : "#vote_recorded_per_minute"
        data_points     : 60
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "Votes"
        update_callback : (data) ->
            total_votes_in_the_last_hour = d3.sum(@counter_data.vote_recorded.map((d) -> d.value))
            $('#total_votes_in_the_last_hour').text(d3.format(",")(total_votes_in_the_last_hour))
    })

    # ------------ PURCHASES ----------- #
    credit_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]

    purchases_per_minute = new BstatsCounterLineGraph({
        counters        : credit_counters
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_minute"
        div_id          : "#purchases_per_minute"
        data_points     : 60
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "Purchases"
        update_callback : (data) ->
            total_purchases_in_the_last_hour = d3.sum(d3.values(@counter_data).map((values) -> d3.sum(values.map((d) -> d.value))))
            $('#total_purchases_in_the_last_hour').text(d3.format(",")(total_purchases_in_the_last_hour))
    })

    # --- PIE CHARTS --- #

    # ------------ purchases ----------- #
    purchase_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]

    purchases_pie = new BstatsCounterPie({
        counters     : purchase_counters
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_minute"
        div_id       : "#purchases_in_the_last_hour_pie"
        data_points  : 60
        width        : Math.min(width, height)
        height       : Math.min(width, height)
        radius       : Math.min(width, height) * 0.45
        inner_title  : "purchases"
    })

    logins_pie = new BstatsCounterPie({
        counters     : login_counters
        socket_url   : "http://#{data.hostname}:#{data.port}/bstats_counters_per_minute"
        div_id       : "#logins_in_the_last_hour_pie"
        data_points  : 60
        width        : Math.min(width, height)
        height       : Math.min(width, height)
        radius       : Math.min(width, height) * 0.45
        inner_title  : "logins"
    })

    $('#container').isotope({
        itemSelector: '.chart'
        animationEngine: 'best-available'
    })
)
