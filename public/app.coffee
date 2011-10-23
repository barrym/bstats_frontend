# ---------- MODELS -------------

window.App = Backbone.Model.extend({
        urlRoot: '/apps'
    })

window.Apps = Backbone.Collection.extend({
        model: App,
        url: '/apps'
        comparator: (app) ->
            app.get('name')
    })

window.Dashboard = Backbone.Model.extend({
        urlRoot: '/dashboards'
        validate: (attributes) ->
            errors = []
            if !attributes.app
                errors.push "app cannot be blank"

            if !attributes.name
                errors.push "name cannot be blank"

            if errors.length != 0
                return errors

    })

window.Dashboards = Backbone.Collection.extend({
        model: Dashboard,
        url: '/dashboards'
        comparator: (dashboard) ->
            dashboard.get('name')
    })

window.dashboards = new Dashboards()

# ----------- VIEWS -------------

window.ErrorView = Backbone.View.extend({ # TODO: inherit from notice class
        className: 'error'

        initialize: () ->
            @template = _.template($('#error-template').html())

        render: () ->
            $(@el).html(@template({errors:this.options.errors}))
            return this
    })

window.DashboardView = Backbone.View.extend({
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

window.DashboardShowView = Backbone.View.extend({
    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#dashboard-show-template').html())

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
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
        @apps = new Apps()

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

        error: (model, errors) ->
            errorView = new ErrorView({errors:errors})
            $('#notices').empty()
            $('#notices').append(errorView.render().el)
        )
        return false

    cancel: () ->
        Backbone.history.navigate("#admin", true)
        return false

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
        $app = this.$('#app')
        @apps.fetch({
            success: (collection, response) ->
                collection.each((app) ->
                    $app.append("<option value='#{app.get('name')}'>#{app.get('name')}</option>")
                )
        })


        return this
    })


# ----------- ROUTER ------------

window.BstatsFrontend = Backbone.Router.extend({
    routes: {
        ''                     : 'home'
        'admin'                : 'admin_index'
        'admin/dashboards/new' : 'admin_dashboards_new'
        'admin/dashboards/:id' : 'admin_dashboards_show'
    }

    initialize: () ->
        @dashboardIndexView = new DashboardIndexView({
            collection: window.dashboards
        })

    home: () ->
        $('#main').empty()
        $('#main').text('home page')

    admin_index: () ->
        $('#main').empty()
        $('#main').append(@dashboardIndexView.render().el)

    admin_dashboards_new: () ->
        @dashboardNewView = new DashboardNewView({})
        $('#main').empty()
        $('#main').append(@dashboardNewView.render().el)

    admin_dashboards_show: (id) ->
        $('#main').empty()
        dashboard = new Dashboard({id:id})
        dashboard.fetch({
            success: (model, resp) ->
                showView = new DashboardShowView({model:model})
                $('#main').append(showView.render().el)

            error: () ->
                $('#main').text("cant find")
        })

    })

$(() ->
    window.BstatsFrontendApp = new BstatsFrontend()
    Backbone.history.start()
)
