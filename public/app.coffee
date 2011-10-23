window.BstatsFrontend = Backbone.Router.extend({
    routes: {
        ''      : 'home',
        'admin' : 'admin'
    }

    initialize: () ->
        # nothing

    home: () ->
        $('#main').empty()
        $('#main').text('home page')

    admin: () ->
        $('#main').empty()
        $('#main').text('admin page')

    })



$(() ->
    window.App = new BstatsFrontend()
    Backbone.history.start()
)
