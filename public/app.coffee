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
        # validate: (attributes) ->
        #     errors = []
        #     if !attributes.app
        #         errors.push "app cannot be blank"

        #     if !attributes.name
        #         errors.push "name cannot be blank"

        #     if errors.length != 0
        #         return errors

    })

window.Dashboards = Backbone.Collection.extend({
        model: Dashboard,
        url: '/dashboards'
        comparator: (dashboard) ->
            dashboard.get('name')
    })

window.dashboards = new Dashboards()

# ----------- VIEWS -------------

window.DashboardIndexView = Backbone.View.extend({
    tagName   : 'section'
    className : 'dashboards'

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#dashboard-index-template').html())
        @collection.bind('reset', @render)
        @collection.bind('remove', @render)

    render: () ->
        $(@el).html(@template({}))
        $dashboards = this.$('#dashboards')
        @collection.each (dashboard) ->
            view = new DashboardIndexItemView({
                model:dashboard,
                collection:@collection
            })
            $dashboards.append(view.render().el)

        return this

    })

window.DashboardIndexItemView = Backbone.View.extend({
    tagName: 'li'
    className:'admin_dashboard'

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#dashboard-index-item-template').html())

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
        return this

    })

window.ErrorView = Backbone.View.extend({ # TODO: inherit from notice class
        className: 'error'

        initialize: () ->
            @template = _.template($('#error-template').html())

        render: () ->
            $(@el).html(@template({errors:this.options.errors}))
            return this
    })

window.AdminDashboardIndexView = Backbone.View.extend({
    tagName   : 'section'
    className : 'dashboards'

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#admin-dashboard-index-template').html())
        @collection.bind('reset', @render)
        @collection.bind('remove', @render)

    render: () ->
        $(@el).html(@template({}))
        $dashboards = this.$('#dashboards')
        @collection.each (dashboard) ->
            view = new AdminDashboardIndexItemView({
                model:dashboard,
                collection:@collection
            })
            $dashboards.append(view.render().el)

        return this

    })

window.AdminDashboardIndexItemView = Backbone.View.extend({
    tagName: 'li'
    className:'admin_dashboard'
    events: {
        'click button' : 'destroy'
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#admin-dashboard-index-item-template').html())

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

window.AdminDashboardShowView = Backbone.View.extend({

    events:{
        'click button.save'  : 'save',
        'click button.add'   : 'add_item',
        'change select.type' : 'type_changed'
    }

    initialize: () ->
        @item_count = 0
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#admin-dashboard-show-template').html())
        @item_template = _.template($('#admin-dashboard-new-item-template').html())

    add_item: () ->
        @add_item_to_canvas({
            top    : 0.2
            left   : 0.2
            height : 0.4
            width  : 0.3
        })

    type_changed: (event) ->
        self = this
        $element = $(event.currentTarget)
        $parent = $element.parent()
        type = $element.val()
        if type == 'line' || type == 'pie'
            $parent.find('.title').show()
        else
            $parent.find('.title').hide()

    save: () ->
        $canvas       = this.$('#canvas')
        canvas_height = $canvas.height()
        canvas_width  = $canvas.width()
        items_to_save = []
        $items        = this.$('#canvas .item')
        $items.each () ->
            console.log("about to save item offset t:#{$(this).offset().top} l:#{$(this).offset().left}")
            console.log("about to save item positi t:#{$(this).position().top} l:#{$(this).position().left}")
            id       = $(this).attr('id')
            height   = Math.round(($(this).height()/canvas_height) * 100)/100
            width    = Math.round(($(this).width()/canvas_width) * 100)/100
            top      = Math.round(($(this).position().top/canvas_height) * 100)/100
            left     = Math.round(($(this).position().left/canvas_width) * 100)/100
            title    = $(this).find('.title').val()
            timestep = $(this).find('.timestep').val()
            type     = $(this).find('.type').val()
            counters = $(this).find('.counters').val()
            console.log("saving item t:#{top} l:#{left} h:#{height} w:#{width}")
            items_to_save.push({
                id       : id,
                height   : height,
                width    : width,
                top      : top,
                left     : left,
                title    : title,
                timestep : timestep,
                type     : type,
                counters : counters

            })

        console.log("items to save:")
        console.log(items_to_save)
        @model.set({items:items_to_save})
        @model.save()

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
        items = this.model.get('items')
        if items
            for item in items
                @add_item_to_canvas(item)

        return this

    add_item_to_canvas: (params) ->
        $canvas       = this.$('#canvas')
        canvas_height = $canvas.height()
        canvas_width  = $canvas.width()
        canvas_top    = $canvas.offset().top
        canvas_left   = $canvas.offset().left
        top           = canvas_top + params.top * canvas_height
        left          = canvas_left + params.left * canvas_width
        height        = canvas_height * params.height
        width         = canvas_width * params.width

        if !params.id
            @item_count = @item_count + 1
            id = @item_count
        else
            id = params.id

        $item = $(@item_template({
            item     : params,
            counters : @model.get('counters')
        }))
        $item.find('.timestep').val(params.timestep)
        $item.find('.type').val(params.type)
        $item.find('.counters').val(params.counters)
        if params.type == 'line' || params.type == 'pie'
            $item.find('.title').show()
        else
            $item.find('.title').hide()

        $canvas.append($item)
        $item.attr('style','position:absolute')
        $item.height(height).width(width).offset({top:top, left:left})
        $item.draggable({
            cursor      : "move"
            containment : "parent"
            stack       : ".item"
            grid        : [10, 10]
            scroll      : false
        }).resizable({
            containment : "parent"
            grid        : 10
            minWidth    : 100
            minHeight   : 100
        })
        $item.hover(() ->
            $(this).css('cursor', 'move')
        )

    })

window.AdminDashboardNewView = Backbone.View.extend({

    events: {
        "submit form" : "save",
        "click button" : "cancel"
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @template = _.template($('#admin-dashboard-new-template').html())
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
            Backbone.history.navigate("#admin/dashboards/#{model.id}", true)

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
        @adminDashboardIndexView = new AdminDashboardIndexView({
            collection: window.dashboards
        })
        @dashboardIndexView = new DashboardIndexView({
            collection: window.dashboards
        })

    home: () ->
        $('#main').empty()
        $('#main').append(@dashboardIndexView.render().el)

    admin_index: () ->
        $('#main').empty()
        $('#main').append(@adminDashboardIndexView.render().el)

    admin_dashboards_new: () ->
        @adminDashboardNewView = new AdminDashboardNewView({})
        $('#main').empty()
        $('#main').append(@adminDashboardNewView.render().el)

    admin_dashboards_show: (id) ->
        $('#main').empty()
        dashboard = new Dashboard({id:id})
        dashboard.fetch({
            success: (model, resp) ->
                showView = new AdminDashboardShowView({model:model})
                $('#main').append(showView.render().el)

            error: () ->
                $('#main').text("cant find")
        })

    })

$(() ->
    window.BstatsFrontendApp = new BstatsFrontend()
    Backbone.history.start()
)
