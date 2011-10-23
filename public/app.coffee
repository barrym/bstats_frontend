# ---------- MODELS -------------
window.App = Backbone.Model.extend({})

window.Apps = Backbone.Collection.extend({
        model: App,
        url: '/apps'
    })

window.apps = new Apps()


window.Dashboard = Backbone.Model.extend({
        urlRoot: '/dashboards'
    })

window.Dashboards = Backbone.Collection.extend({
        model: Dashboard,
        url: '/dashboards'
        comparator: (dashboard) ->
            dashboard.get('name')
    })

window.dashboards = new Dashboards()

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

window.DashboardView = Backbone.View.extend({
    tagName: 'li'
    className:'dashboard'
    events: {
        'click button' : 'destroy'
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#dashboard-template').html())

    destroy: () ->
        @model.destroy({
            success:(model, res) ->
                window.dashboards.remove(model)

            error:(model, res) ->
                console.log("error deleting")
                console.log(res)
        })
        return false

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
        return this

    })

window.AppIndexView = Backbone.View.extend({
    tagName: 'section'
    className: 'apps'

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#app-index-template').html())
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

window.DashboardIndexView = Backbone.View.extend({
    tagName: 'section'
    className: 'dashboards'

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#dashboard-index-template').html())
        @collection.bind('reset', @render)
        @collection.bind('remove', @render)

    render: () ->
        $(@el).html(@template({}))
        $dashboards = this.$('#dashboards')
        @collection.each (dashboard) ->
            view = new DashboardView({
                model:dashboard,
                collection:@collection
            })
            $dashboards.append(view.render().el)

        return this

    })

window.DashboardNewView = Backbone.View.extend({

    events: {
        "submit form" : "save",
        "click button" : "cancel"
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#dashboard-new-template').html())
        @model = new Dashboard()

    save: () ->
        self = this
        @model.save({
            name     : this.$('#name').val()
            app      : this.$('#app').val()
            counters : this.$('#counters').val()
        },
        success: (model, res) ->
            dashboards.add(model)
            Backbone.history.navigate("#admin", true)

        error: (model, res) ->
            console.log("error")
            console.log(res)
        )
        return false

    cancel: () ->
        Backbone.history.navigate("#admin", true)
        return false

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)

        return this
    })


# ----------- ROUTER ------------

window.BstatsFrontend = Backbone.Router.extend({
    routes: {
        ''                     : 'home',
        'admin'                : 'admin_index',
        'admin/dashboards/new' : 'admin_dashboards_new'
    }

    initialize: () ->
        @appIndexView = new AppIndexView({
            collection: window.apps
        })
        @dashboardIndexView = new DashboardIndexView({
            collection: window.dashboards
        })
        # @dashboardNewView = new DashboardNewView({})

    home: () ->
        $('#main').empty()
        $('#main').text('home page')

    admin_index: () ->
        $('#main').empty()
        $('#main').append(@dashboardIndexView.render().el)
        $('#main').append(@appIndexView.render().el)

    admin_dashboards_new: () ->
        @dashboardNewView = new DashboardNewView({})
        $('#main').empty()
        $('#main').append(@dashboardNewView.render().el)

    })

$(() ->
    window.BstatsFrontendApp = new BstatsFrontend()
    Backbone.history.start()
)
