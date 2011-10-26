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

    events:{
        'click button.save'  : 'save',
        'click button.add'   : 'add_item',
        'change select.type' : 'type_changed'
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#dashboard-show-template').html())
        @item_template = _.template($('#dashboard-new-item-template').html())

    add_item: () ->
        top    = this.$('#canvas').position().top + 10
        left   = this.$('#canvas').position().left + 10
        height = 250
        width  = 250

        $newItem    = $(@item_template({
            counters:@model.get('counters')
        }))
        @add_item_to_canvas($newItem, top, left, height, width)

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
        item_count = 0
        content = @template(@model.toJSON())
        $(@el).html(content)
        items = this.model.get('items')
        if items
            $canvas       = this.$('#canvas')
            canvas_height = $canvas.height()
            canvas_width  = $canvas.width()
            canvas_top    = $canvas.position().top
            canvas_left   = $canvas.position().left

            canvas_top = 228
            canvas_left = 375
            console.log("canvas: t:#{canvas_top} l:#{canvas_left} h:#{canvas_height} w:#{canvas_width}")

            for item in items
                top    = canvas_top + item.top * canvas_height
                left   = canvas_left + item.left * canvas_width
                height = canvas_height * item.height
                width  = canvas_width * item.width
                item_count = item_count + 1
                newItem = $(@item_template({
                    id:item_count,
                    counters:@model.get('counters')
                })).append("<b>#{item_count}</b>")
                # newItem.offset({top:top, left:left})
                console.log("adding item #{item_count} t:#{top} l:#{left} h:#{height} w:#{width}")
                @add_item_to_canvas(newItem, top, left, height, width)

        return this

    add_item_to_canvas: (item, top, left, height, width) ->
        item.draggable({
            containment : "parent"
            stack       : ".item"
            grid        : [10, 10]
            scroll      : false
        }).resizable({
            containment : "parent"
            grid        : 10
            minWidth    : 100
            minHeight   : 100
        }).height(height).width(width).offset({top:top, left:left})
        $canvas = this.$('#canvas')
        $canvas.append(item)
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
