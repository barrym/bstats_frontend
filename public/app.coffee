# ---------- MODELS -------------

window.Namespace = Backbone.Model.extend({
        urlRoot: '/namespaces'
})

window.Namespaces = Backbone.Collection.extend({
        model: Namespace,
        url: '/namespaces'
        comparator: (namespace) ->
            namespace.get('name')
})

window.Dashboard = Backbone.Model.extend({
        urlRoot: '/dashboards'
        # validate: (attributes) ->
        #     errors = []
        #     if !attributes.namespace
        #         errors.push "Namespace cannot be blank"

        #     if !attributes.name
        #         errors.push "Name cannot be blank"

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
        $dashboards = this.$('#dashboards tbody')
        @collection.each (dashboard) ->
            view = new DashboardIndexItemView({
                model      : dashboard,
                collection : @collection
            })
            $dashboards.append(view.render().el)

        return this
})

window.DashboardIndexItemView = Backbone.View.extend({
    tagName: 'tr'

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#dashboard-index-item-template').html())

    render: () ->
        content = @template(@model.toJSON())
        $(@el).html(content)
        return this

})

window.DashboardView = Backbone.View.extend({
    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#dashboard-template').html())

    render: () ->
        content = @template({})
        $(@el).html(content)
        document.title = @model.get('name')

        for counter, color of @model.get('colors')
            $("<style>
                #items path.#{counter} { stroke: #{color};}
                #items g.arc path.#{counter} { fill: #{color};}
                circle.#{counter} { fill: #{color};}
               </style>").appendTo("head")

        window_width   = $(document).width()
        window_height  = $(document).height()
        items          = @model.get('items')
        if items
            $.get('/config', (data) =>
                graphs = {
                    'per_second' : [],
                    'per_minute' : []
                }
                for item in items
                    if item.type == 'legend'
                        #TODO: should this be part of bstats.coffee?
                        width  = window_width * item.width
                        height = window_height * item.height
                        $legend = $("<div id='legend'></div>")
                        $legend.offset({top:(item.top * window_height), left:(item.left * window_width)})
                        $legend.height(height)
                        $legend.width(width)
                        $legend.css('position', 'absolute')
                        $('#items').append($legend)
                        legend_size = "#{Math.round($(document).height() * 0.03)}"
                        legend_margin = "0 #{legend_size/3}px 0 0"
                        for legend in @model.get('legends')
                            $legend.append("
                                <div class='legend_item'>
                                    <div class='square' style='background-color:#{legend.color};width:#{legend_size}px;height:#{legend_size}px;margin:#{legend_margin};'></div>
                                    <div style='font-size:#{legend_size}px'>#{legend.title}</div>
                                </div>
                            ")
                    else
                        div_id = "item_#{item.id}"
                        width  = window_width * item.width
                        height = window_height * item.height
                        $graph = $("<div id='#{div_id}' class='item'></div>")
                        $graph.offset({top:(item.top * window_height), left:(item.left * window_width)})
                        $graph.height(height)
                        $graph.width(width)
                        $graph.css('position', 'absolute')
                        $('#items').append($graph)

                        graphs[item.timestep].push(new BstatsCounterItem({
                            type         : item.type
                            sub_type     : item.sub_type
                            counters     : item.counters
                            timestep     : item.timestep
                            div_id       : "##{div_id}"
                            title        : item.title
                        }))

                for timestep, timestep_graphs of graphs
                    @init_graphs data.hostname, data.port, timestep, timestep_graphs
            )


        return this

    init_graphs: (hostname, port, timestep, graphs) ->
        if graphs.length != 0
            socket = io.connect("http://#{hostname}:#{port}/bstats")

            socket.emit('dashboard_subscribe', {
                type         : 'counters',
                id           : @model.id,
                timestep     : timestep
            })

            socket.on 'refresh', () ->
                location.reload()

            socket.on timestep, (new_data) ->
                for graph in graphs
                    graph.process_new_data(new_data)

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
        $dashboards = this.$('#dashboards tbody')
        @collection.each (dashboard) ->
            view = new AdminDashboardIndexItemView({
                model      : dashboard,
                collection : @collection
            })
            $dashboards.append(view.render().el)

        return this

})

window.AdminDashboardIndexItemView = Backbone.View.extend({
    tagName        : 'tr'
    className      : 'admin_dashboard'
    events         : {
        'click button' : 'destroy'
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @model.bind('change', @render)
        @template = _.template($('#admin-dashboard-index-item-template').html())

    destroy: () ->
        if confirm("Are you sure you want to delete #{@model.get('name')}?")
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
        'click button#save'    : 'save',
        'click button#add'     : 'add_item',
        'click button#remove'  : 'remove_item',
        'change input.colors'  : 'update_color_box',
        'click button#add-legend' : 'add_legend'
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

    remove_item: (event) ->
        $(event.currentTarget).parent().remove()

    update_color_box: (event) ->
        $parent = $(event.currentTarget).parent()
        $parent.find('.color_legend').css('background-color', $(event.currentTarget).val())

    add_legend: () ->
        $('#legends').append('
                    <div class="legend">
                        <div class="color_legend"></div>
                        <input class="colors" type="text" name="color" placeholder="Color">
                        <input type="text" name="title" placeholder="Title">
                        Remove button here
                    </div>
        ')

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
            sub_type = switch type
                when 'text'
                    $(this).find('.text-type').val()
                else
                    undefined

            counters = $(this).find('.counters').val()
            items_to_save.push({
                id       : id,
                height   : height,
                width    : width,
                top      : top,
                left     : left,
                title    : title,
                timestep : timestep,
                type     : type,
                sub_type : sub_type,
                counters : counters

            })

        colors_to_save = {}
        for counter in @model.get('counters')
            colors_to_save[counter] =  $("#color_#{counter}").val()

        legends_to_save = []
        $('#legends .legend').each () ->
            legends_to_save.push {
                title:$(this).find('input[name=title]').val()
                color:$(this).find('input[name=color]').val()
            }

        @model.set({
            items   : items_to_save,
            colors  : colors_to_save,
            legends : legends_to_save,
            name    : $('#name').val() # TODO : this doesnt refresh the name on the collections page
        })
        @model.save()

    render: () ->
        params = @model.toJSON()
        if !params.legends
            params.legends = []
        content = @template(params)
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
            # TODO: is this needed still?
            @item_count = @item_count + 1
            id = @item_count
        else
            id = params.id

        $item = $(@item_template({
            item     : params,
            counters : @model.get('counters')
        }))

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
            minHeight   : 30
        })
        $item.hover(() ->
            $(this).css('cursor', 'move')
        )
        $item.find('.timestep').val(params.timestep)
        $item.find('.type').val(params.type)
        $item.find('.counters').val(params.counters)
        if params.type == 'text'
            $item.find('.text-type').val(params.sub_type)
        this.show_and_hide_config($item, params.type)

        $item.find('.details').popover({
            html      : true,
            placement : 'below',
            trigger   : 'manual',
            title     : () -> $item.find('#details_form .title').val() || "Edit details",
            content   : () ->
                $item.find('#details_form').html()

        })
        self = this # Hacky?
        $item.find('.details').click () ->
            $('.details').each(() -> $(this).popover('hide'))

            $item.find('.details').popover('show')

            # Configure popover
            $('.popover').css('z-index', 1003)
            $('.popover p .title').val($item.find('#details_form .title').val())
            $('.popover p .timestep').val($item.find('#details_form .timestep').val())
            $('.popover p .type').val($item.find('#details_form .type').val())
            $('.popover p .text-type').val($item.find('#details_form .text-type').val())
            $('.popover p .counters').val($item.find('#details_form .counters').val())

            $('.popover p #counter_link').click () ->
                $('.popover p .counters').toggle()
                if $('.popover p .counters').is(':visible')
                    $('.popover p #counter_link').text("Hide counters")
                else
                    $('.popover p #counter_link').text("View counters")
                return false
            self.show_and_hide_config($('.popover p'), $item.find('#details_form .type').val())
            $('.popover p .type').change () ->
                type = $(this).parent().find('.type').val()
                self.show_and_hide_config($(this).parent(), type)

            # On close
            $('.popover button#done').click () ->
                title    = $(this).parent().find('.title').val()
                timestep = $(this).parent().find('.timestep').val()
                type     = $(this).parent().find('.type').val()
                if type == 'legend'
                    title = "Legend"
                counters = $(this).parent().find('.counters').val()
                sub_type = switch type
                    when 'text'
                        $(this).parent().find('.text-type').val()
                    else
                        undefined

                $item.find('#details_form .title').val(title)
                $item.find('#details_form .timestep').val(timestep)
                $item.find('#details_form .type').val(type)
                $item.find('#details_form .text-type').val(sub_type)
                $item.find('#details_form .counters').val(counters)
                $item.find('#item-title').text(title)

                $item.find('.details').popover('hide')

    show_and_hide_config: (container, type) ->
        switch type
            when 'line'
                container.find('.title-input').show()
                container.find('.text-type-input').hide()
                container.find('.timestep-input').show()
            when 'pie'
                container.find('.title-input').show()
                container.find('.text-type-input').hide()
                container.find('.timestep-input').show()
            when 'text'
                container.find('.title-input').show()
                container.find('.text-type-input').show()
                container.find('.timestep-input').show()
            when 'legend'
                container.find('.title-input').hide()
                container.find('.text-type-input').hide()
                container.find('.timestep-input').hide()
            else
                container.find('.title-input').hide()
                container.find('.text-type-input').hide()
                container.find('.timestep-input').hide()
})

window.AdminDashboardNewView = Backbone.View.extend({

    events: {
        "submit form" : "save",
        "click button" : "cancel"
    }

    initialize: () ->
        _.bindAll(this, 'render')
        @template   = _.template($('#admin-dashboard-new-template').html())
        @model      = new Dashboard()
        @namespaces = new Namespaces()

    save: () ->
        @model.save({
            name      : this.$('#name').val()
            namespace : this.$('#namespace').val()
            counters  : this.$('#counters').val()
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
        $namespace = this.$('#namespace')
        @namespaces.fetch({
            success: (collection, response) ->
                collection.each((namespace) ->
                    $namespace.append("<option value='#{namespace.get('name')}'>#{namespace.get('name')}</option>")
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
        'dashboards/:id'       : 'dashboard'
    }

    initialize: () ->
        @adminDashboardIndexView = new AdminDashboardIndexView({
            collection: window.dashboards
        })

    home: () ->
        dashboardIndexView = new DashboardIndexView({
            collection: window.dashboards
        })
        $('#home_link').addClass('active')
        $('#admin_link').removeClass('active')
        $('#main').empty()
        $('#main').append(dashboardIndexView.render().el)

    dashboard: (id) ->
        dashboard = new Dashboard({id:id})
        dashboard.fetch({
            success: (model, resp) ->
                $('body').empty()
                $('body').toggleClass('dashboard')
                showView = new DashboardView({model:model})
                $('body').append(showView.render().el)

            error: () ->
                $('#main').empty()
                $('#main').text("cant find this dashboard")
        })

    admin_index: () ->
        $('#home_link').removeClass('active')
        $('#admin_link').addClass('active')
        $('#main').empty()
        $('#main').append(@adminDashboardIndexView.render().el)

    admin_dashboards_new: () ->
        $('#home_link').removeClass('active')
        $('#admin_link').addClass('active')
        @adminDashboardNewView = new AdminDashboardNewView({})
        $('#main').empty()
        $('#main').append(@adminDashboardNewView.render().el)

    admin_dashboards_show: (id) ->
        $('#home_link').removeClass('active')
        $('#admin_link').addClass('active')
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
