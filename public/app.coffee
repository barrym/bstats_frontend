# ---------- MODELS -------------
window.App = Backbone.Model.extend({


    })

window.Apps = Backbone.Collection.extend({
        model: App,
        url: '/apps'
    })

window.apps = new Apps()

# ----------- VIEWS -------------

window.AppView = Backbone.View.extend({
    tagName: 'li'
    className:'app'

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#app-template').html())

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
        return this

    })

window.AdminIndexView = Backbone.View.extend({
    tagName: 'section'
    className: 'apps'

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#admin-index-template').html())
        @collection.bind('reset', @render)

    render: () ->
        $(@el).html(@template({}))
        $apps = this.$('#apps')
        @collection.each (app) ->
            view = new AppView({
                model:app,
                collection:@collection
            })
            $apps.append(view.render().el)
        return this

    })


# ----------- ROUTER ------------

window.BstatsFrontend = Backbone.Router.extend({
    routes: {
        ''      : 'home',
        'admin' : 'admin_index'
    }

    initialize: () ->
        @adminIndexView = new AdminIndexView({
            collection: window.apps
        })

    home: () ->
        $('#main').empty()
        $('#main').text('home page')

    admin_index: () ->
        $('#main').empty()
        $('#main').append(@adminIndexView.render().el)

    })

$(() ->
    window.BstatsFrontendApp = new BstatsFrontend()
    Backbone.history.start()
)
