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
