$.get('/config', (data) ->
    width  = ($(window).width() - 20) * 0.47
    height = $(window).height() * 0.35

    per_second_height = height * 3/4
    per_second_y_ticks = 5
    per_minute_height = height/2
    per_minute_y_ticks = 3

    # --- LINE CHARTS --- #

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
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Logins per second"
    })

    logins_per_minute = new BstatsCounterLineGraph({
        counters     : login_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#logins_per_minute"
        data_points  : 60
        socket_path  : 'bstats_counters_per_minute'
        width        : width
        height       : per_minute_height
        y_tick_count : per_minute_y_ticks
        title        : "Logins per minute"
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
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Votes per second"
    })

    votes_per_minute = new BstatsCounterLineGraph({
        counters        : ["vote_recorded"]
        hostname        : data.hostname
        port            : data.port
        div_id          : "#vote_recorded_per_minute"
        data_points     : 60
        socket_path     : 'bstats_counters_per_minute'
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "Votes per minute"
        update_callback : (data) ->
            total_votes_in_the_last_hour = d3.sum(@counter_data.vote_recorded.map((d) -> d.value))
            $('#total_votes_in_the_last_hour').text(d3.format(",")(total_votes_in_the_last_hour))
    })

    # ------------ purchases ----------- #
    credit_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]
    purchases_per_second = new BstatsCounterLineGraph({
        counters     : credit_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#purchases_per_second"
        data_points  : 300
        socket_path  : 'bstats_counters_per_second'
        width        : width
        height       : per_second_height
        y_tick_count : per_second_y_ticks
        title        : "Purchases per second"
    })

    purchases_per_minute = new BstatsCounterLineGraph({
        counters        : credit_counters
        hostname        : data.hostname
        port            : data.port
        div_id          : "#purchases_per_minute"
        data_points     : 60
        socket_path     : 'bstats_counters_per_minute'
        width           : width
        height          : per_minute_height
        y_tick_count : per_minute_y_ticks
        title           : "Purchases per minute"
        update_callback : (data) ->
            total_purchases_in_the_last_hour = d3.sum(d3.values(@counter_data).map((values) -> d3.sum(values.map((d) -> d.value))))
            $('#total_purchases_in_the_last_hour').text(d3.format(",")(total_purchases_in_the_last_hour))
    })

    # --- PIE CHARTS --- #

    # ------------ purchases ----------- #
    credit_counters = [
        "facebook_purchase_success",
        "psms_purchase_success",
        "itunes_purchase_success"
    ]

    new BstatsCounterPie({
        counters     : credit_counters
        hostname     : data.hostname
        port         : data.port
        div_id       : "#purchases_in_the_last_hour_pie"
        data_points  : 60
        socket_path  : 'bstats_counters_per_minute'
        width        : width
        height       : height
        radius       : Math.min(width, height) * 0.4
        title        : "Purchases in the last hour"
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
