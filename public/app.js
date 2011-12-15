
window.Namespace = Backbone.Model.extend({
  urlRoot: '/namespaces'
});

window.Namespaces = Backbone.Collection.extend({
  model: Namespace,
  url: '/namespaces',
  comparator: function(namespace) {
    return namespace.get('name');
  }
});

window.Dashboard = Backbone.Model.extend({
  urlRoot: '/dashboards'
});

window.Dashboards = Backbone.Collection.extend({
  model: Dashboard,
  url: '/dashboards',
  comparator: function(dashboard) {
    return dashboard.get('name');
  }
});

window.dashboards = new Dashboards();

window.DashboardIndexView = Backbone.View.extend({
  tagName: 'section',
  className: 'dashboards',
  initialize: function() {
    _.bindAll(this, 'render');
    this.template = _.template($('#dashboard-index-template').html());
    this.collection.bind('reset', this.render);
    return this.collection.bind('remove', this.render);
  },
  render: function() {
    var $dashboards;
    $(this.el).html(this.template({}));
    $dashboards = this.$('#dashboards tbody');
    this.collection.each(function(dashboard) {
      var view;
      view = new DashboardIndexItemView({
        model: dashboard,
        collection: this.collection
      });
      return $dashboards.append(view.render().el);
    });
    return this;
  }
});

window.DashboardIndexItemView = Backbone.View.extend({
  tagName: 'tr',
  initialize: function() {
    _.bindAll(this, 'render');
    this.model.bind('change', this.render);
    return this.template = _.template($('#dashboard-index-item-template').html());
  },
  render: function() {
    var content;
    content = this.template(this.model.toJSON());
    $(this.el).html(content);
    return this;
  }
});

window.DashboardView = Backbone.View.extend({
  initialize: function() {
    _.bindAll(this, 'render');
    this.model.bind('change', this.render);
    return this.template = _.template($('#dashboard-template').html());
  },
  render: function() {
    var color, content, counter, items, window_height, window_width, _ref;
    var _this = this;
    content = this.template({});
    $(this.el).html(content);
    document.title = this.model.get('name');
    _ref = this.model.get('colors');
    for (counter in _ref) {
      color = _ref[counter];
      $("<style>                #items path." + counter + " { stroke: " + color + ";}                #items g.arc path." + counter + " { fill: " + color + ";}                circle." + counter + " { fill: " + color + ";}               </style>").appendTo("head");
    }
    window_width = $(document).width();
    window_height = $(document).height();
    items = this.model.get('items');
    if (items) {
      $.get('/config', function(data) {
        var $graph, $legend, div_id, graphs, height, item, legend, legend_margin, legend_size, timestep, timestep_graphs, width, _i, _j, _len, _len2, _ref2, _results;
        graphs = {
          'per_second': [],
          'per_minute': []
        };
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          if (item.type === 'legend') {
            width = window_width * item.width;
            height = window_height * item.height;
            $legend = $("<div id='legend'></div>");
            $legend.offset({
              top: item.top * window_height,
              left: item.left * window_width
            });
            $legend.height(height);
            $legend.width(width);
            $legend.css('position', 'absolute');
            $('#items').append($legend);
            legend_size = "" + (Math.round($(document).height() * 0.03));
            legend_margin = "0 " + (legend_size / 3) + "px 0 0";
            _ref2 = _this.model.get('legends');
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              legend = _ref2[_j];
              $legend.append("                                <div class='legend_item'>                                    <div class='square' style='background-color:" + legend.color + ";width:" + legend_size + "px;height:" + legend_size + "px;margin:" + legend_margin + ";'></div>                                    <div style='font-size:" + legend_size + "px'>" + legend.title + "</div>                                </div>                            ");
            }
          } else {
            div_id = "item_" + item.id;
            width = window_width * item.width;
            height = window_height * item.height;
            $graph = $("<div id='" + div_id + "' class='item'></div>");
            $graph.offset({
              top: item.top * window_height,
              left: item.left * window_width
            });
            $graph.height(height);
            $graph.width(width);
            $graph.css('position', 'absolute');
            $('#items').append($graph);
            graphs[item.timestep].push(new BstatsCounterItem({
              type: item.type,
              sub_type: item.sub_type,
              counters: item.counters,
              timestep: item.timestep,
              div_id: "#" + div_id,
              title: item.title
            }));
          }
        }
        _results = [];
        for (timestep in graphs) {
          timestep_graphs = graphs[timestep];
          _results.push(_this.init_graphs(data.hostname, data.port, timestep, timestep_graphs));
        }
        return _results;
      });
    }
    return this;
  },
  init_graphs: function(hostname, port, timestep, graphs) {
    var socket;
    if (graphs.length !== 0) {
      socket = io.connect("http://" + hostname + ":" + port + "/bstats");
      socket.emit('dashboard_subscribe', {
        type: 'counters',
        id: this.model.id,
        timestep: timestep
      });
      socket.on('refresh', function() {
        return location.reload();
      });
      return socket.on(timestep, function(new_data) {
        var graph, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = graphs.length; _i < _len; _i++) {
          graph = graphs[_i];
          _results.push(graph.process_new_data(new_data));
        }
        return _results;
      });
    }
  }
});

window.ErrorView = Backbone.View.extend({
  className: 'error',
  initialize: function() {
    return this.template = _.template($('#error-template').html());
  },
  render: function() {
    $(this.el).html(this.template({
      errors: this.options.errors
    }));
    return this;
  }
});

window.AdminDashboardIndexView = Backbone.View.extend({
  tagName: 'section',
  className: 'dashboards',
  initialize: function() {
    _.bindAll(this, 'render');
    this.template = _.template($('#admin-dashboard-index-template').html());
    this.collection.bind('reset', this.render);
    return this.collection.bind('remove', this.render);
  },
  render: function() {
    var $dashboards;
    $(this.el).html(this.template({}));
    $dashboards = this.$('#dashboards tbody');
    this.collection.each(function(dashboard) {
      var view;
      view = new AdminDashboardIndexItemView({
        model: dashboard,
        collection: this.collection
      });
      return $dashboards.append(view.render().el);
    });
    return this;
  }
});

window.AdminDashboardIndexItemView = Backbone.View.extend({
  tagName: 'tr',
  className: 'admin_dashboard',
  events: {
    'click button': 'destroy'
  },
  initialize: function() {
    _.bindAll(this, 'render');
    this.model.bind('change', this.render);
    return this.template = _.template($('#admin-dashboard-index-item-template').html());
  },
  destroy: function() {
    if (confirm("Are you sure you want to delete " + (this.model.get('name')) + "?")) {
      this.model.destroy({
        success: function(model, res) {
          return window.dashboards.remove(model);
        },
        error: function(model, res) {
          console.log("error deleting");
          return console.log(res);
        }
      });
    }
    return false;
  },
  render: function() {
    var content;
    content = this.template(this.model.toJSON());
    $(this.el).html(content);
    return this;
  }
});

window.AdminDashboardShowView = Backbone.View.extend({
  events: {
    'click button#save': 'save',
    'click button#add': 'add_item',
    'click button#remove': 'remove_item',
    'change input.colors': 'update_color_box',
    'click button#add-legend': 'add_legend'
  },
  initialize: function() {
    this.item_count = 0;
    _.bindAll(this, 'render');
    this.model.bind('change', this.render);
    this.template = _.template($('#admin-dashboard-show-template').html());
    return this.item_template = _.template($('#admin-dashboard-new-item-template').html());
  },
  add_item: function() {
    return this.add_item_to_canvas({
      top: 0.2,
      left: 0.2,
      height: 0.4,
      width: 0.3
    });
  },
  remove_item: function(event) {
    return $(event.currentTarget).parent().remove();
  },
  update_color_box: function(event) {
    var $parent;
    $parent = $(event.currentTarget).parent();
    return $parent.find('.color_legend').css('background-color', $(event.currentTarget).val());
  },
  add_legend: function() {
    return $('#legends').append('\
                    <div class="legend">\
                        <div class="color_legend"></div>\
                        <input class="colors" type="text" name="color" placeholder="Color">\
                        <input type="text" name="title" placeholder="Title">\
                        Remove button here\
                    </div>\
        ');
  },
  save: function() {
    var $canvas, $items, canvas_height, canvas_width, colors_to_save, counter, items_to_save, legends_to_save, _i, _len, _ref;
    $canvas = this.$('#canvas');
    canvas_height = $canvas.height();
    canvas_width = $canvas.width();
    items_to_save = [];
    $items = this.$('#canvas .item');
    $items.each(function() {
      var counters, height, id, left, sub_type, timestep, title, top, type, width;
      id = $(this).attr('id');
      height = Math.round(($(this).height() / canvas_height) * 100) / 100;
      width = Math.round(($(this).width() / canvas_width) * 100) / 100;
      top = Math.round(($(this).position().top / canvas_height) * 100) / 100;
      left = Math.round(($(this).position().left / canvas_width) * 100) / 100;
      title = $(this).find('.title').val();
      timestep = $(this).find('.timestep').val();
      type = $(this).find('.type').val();
      sub_type = (function() {
        switch (type) {
          case 'text':
            return $(this).find('.text-type').val();
          default:
            return;
        }
      }).call(this);
      counters = $(this).find('.counters').val();
      return items_to_save.push({
        id: id,
        height: height,
        width: width,
        top: top,
        left: left,
        title: title,
        timestep: timestep,
        type: type,
        sub_type: sub_type,
        counters: counters
      });
    });
    colors_to_save = {};
    _ref = this.model.get('counters');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      counter = _ref[_i];
      colors_to_save[counter] = $("#color_" + counter).val();
    }
    legends_to_save = [];
    $('#legends .legend').each(function() {
      return legends_to_save.push({
        title: $(this).find('input[name=title]').val(),
        color: $(this).find('input[name=color]').val()
      });
    });
    this.model.set({
      items: items_to_save,
      colors: colors_to_save,
      legends: legends_to_save,
      name: $('#name').val()
    });
    return this.model.save();
  },
  render: function() {
    var content, item, items, params, _i, _len;
    params = this.model.toJSON();
    if (!params.legends) params.legends = [];
    content = this.template(params);
    $(this.el).html(content);
    items = this.model.get('items');
    if (items) {
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        this.add_item_to_canvas(item);
      }
    }
    return this;
  },
  add_item_to_canvas: function(params) {
    var $canvas, $item, canvas_height, canvas_left, canvas_top, canvas_width, height, id, left, self, top, width;
    $canvas = this.$('#canvas');
    canvas_height = $canvas.height();
    canvas_width = $canvas.width();
    canvas_top = $canvas.offset().top;
    canvas_left = $canvas.offset().left;
    top = canvas_top + params.top * canvas_height;
    left = canvas_left + params.left * canvas_width;
    height = canvas_height * params.height;
    width = canvas_width * params.width;
    if (!params.id) {
      this.item_count = this.item_count + 1;
      id = this.item_count;
    } else {
      id = params.id;
    }
    $item = $(this.item_template({
      item: params,
      counters: this.model.get('counters')
    }));
    $canvas.append($item);
    $item.attr('style', 'position:absolute');
    $item.height(height).width(width).offset({
      top: top,
      left: left
    });
    $item.draggable({
      cursor: "move",
      containment: "parent",
      stack: ".item",
      grid: [10, 10],
      scroll: false
    }).resizable({
      containment: "parent",
      grid: 10,
      minWidth: 100,
      minHeight: 30
    });
    $item.hover(function() {
      return $(this).css('cursor', 'move');
    });
    $item.find('.timestep').val(params.timestep);
    $item.find('.type').val(params.type);
    $item.find('.counters').val(params.counters);
    if (params.type === 'text') $item.find('.text-type').val(params.sub_type);
    this.show_and_hide_config($item, params.type);
    $item.find('.details').popover({
      html: true,
      placement: 'below',
      trigger: 'manual',
      title: function() {
        return $item.find('#details_form .title').val() || "Edit details";
      },
      content: function() {
        return $item.find('#details_form').html();
      }
    });
    self = this;
    return $item.find('.details').click(function() {
      $('.details').each(function() {
        return $(this).popover('hide');
      });
      $item.find('.details').popover('show');
      $('.popover').css('z-index', 1003);
      $('.popover p .title').val($item.find('#details_form .title').val());
      $('.popover p .timestep').val($item.find('#details_form .timestep').val());
      $('.popover p .type').val($item.find('#details_form .type').val());
      $('.popover p .text-type').val($item.find('#details_form .text-type').val());
      $('.popover p .counters').val($item.find('#details_form .counters').val());
      $('.popover p #counter_link').click(function() {
        $('.popover p .counters').toggle();
        if ($('.popover p .counters').is(':visible')) {
          $('.popover p #counter_link').text("Hide counters");
        } else {
          $('.popover p #counter_link').text("View counters");
        }
        return false;
      });
      self.show_and_hide_config($('.popover p'), $item.find('#details_form .type').val());
      $('.popover p .type').change(function() {
        var type;
        type = $(this).parent().find('.type').val();
        return self.show_and_hide_config($(this).parent(), type);
      });
      return $('.popover button#done').click(function() {
        var counters, sub_type, timestep, title, type;
        title = $(this).parent().find('.title').val();
        timestep = $(this).parent().find('.timestep').val();
        type = $(this).parent().find('.type').val();
        if (type === 'legend') title = "Legend";
        counters = $(this).parent().find('.counters').val();
        sub_type = (function() {
          switch (type) {
            case 'text':
              return $(this).parent().find('.text-type').val();
            default:
              return;
          }
        }).call(this);
        $item.find('#details_form .title').val(title);
        $item.find('#details_form .timestep').val(timestep);
        $item.find('#details_form .type').val(type);
        $item.find('#details_form .text-type').val(sub_type);
        $item.find('#details_form .counters').val(counters);
        $item.find('#item-title').text(title);
        return $item.find('.details').popover('hide');
      });
    });
  },
  show_and_hide_config: function(container, type) {
    switch (type) {
      case 'line':
        container.find('.title-input').show();
        container.find('.text-type-input').hide();
        return container.find('.timestep-input').show();
      case 'pie':
        container.find('.title-input').show();
        container.find('.text-type-input').hide();
        return container.find('.timestep-input').show();
      case 'text':
        container.find('.title-input').show();
        container.find('.text-type-input').show();
        return container.find('.timestep-input').show();
      case 'legend':
        container.find('.title-input').hide();
        container.find('.text-type-input').hide();
        return container.find('.timestep-input').hide();
      default:
        container.find('.title-input').hide();
        container.find('.text-type-input').hide();
        return container.find('.timestep-input').hide();
    }
  }
});

window.AdminDashboardNewView = Backbone.View.extend({
  events: {
    "submit form": "save",
    "click button": "cancel"
  },
  initialize: function() {
    _.bindAll(this, 'render');
    this.template = _.template($('#admin-dashboard-new-template').html());
    this.model = new Dashboard();
    return this.namespaces = new Namespaces();
  },
  save: function() {
    this.model.save({
      name: this.$('#name').val(),
      namespace: this.$('#namespace').val(),
      counters: this.$('#counters').val()
    }, {
      success: function(model, res) {
        dashboards.add(model);
        return Backbone.history.navigate("#admin/dashboards/" + model.id, true);
      },
      error: function(model, errors) {
        var errorView;
        errorView = new ErrorView({
          errors: errors
        });
        $('#notices').empty();
        return $('#notices').append(errorView.render().el);
      }
    });
    return false;
  },
  cancel: function() {
    Backbone.history.navigate("#admin", true);
    return false;
  },
  render: function() {
    var $namespace, content;
    content = this.template(this.model.toJSON());
    $(this.el).html(content);
    $namespace = this.$('#namespace');
    this.namespaces.fetch({
      success: function(collection, response) {
        return collection.each(function(namespace) {
          return $namespace.append("<option value='" + (namespace.get('name')) + "'>" + (namespace.get('name')) + "</option>");
        });
      }
    });
    return this;
  }
});

window.BstatsFrontend = Backbone.Router.extend({
  routes: {
    '': 'home',
    'admin': 'admin_index',
    'admin/dashboards/new': 'admin_dashboards_new',
    'admin/dashboards/:id': 'admin_dashboards_show',
    'dashboards/:id': 'dashboard'
  },
  initialize: function() {
    return this.adminDashboardIndexView = new AdminDashboardIndexView({
      collection: window.dashboards
    });
  },
  home: function() {
    var dashboardIndexView;
    dashboardIndexView = new DashboardIndexView({
      collection: window.dashboards
    });
    $('#home_link').addClass('active');
    $('#admin_link').removeClass('active');
    $('#main').empty();
    return $('#main').append(dashboardIndexView.render().el);
  },
  dashboard: function(id) {
    var dashboard;
    dashboard = new Dashboard({
      id: id
    });
    return dashboard.fetch({
      success: function(model, resp) {
        var showView;
        $('body').empty();
        $('body').toggleClass('dashboard');
        showView = new DashboardView({
          model: model
        });
        return $('body').append(showView.render().el);
      },
      error: function() {
        $('#main').empty();
        return $('#main').text("cant find this dashboard");
      }
    });
  },
  admin_index: function() {
    $('#home_link').removeClass('active');
    $('#admin_link').addClass('active');
    $('#main').empty();
    return $('#main').append(this.adminDashboardIndexView.render().el);
  },
  admin_dashboards_new: function() {
    $('#home_link').removeClass('active');
    $('#admin_link').addClass('active');
    this.adminDashboardNewView = new AdminDashboardNewView({});
    $('#main').empty();
    return $('#main').append(this.adminDashboardNewView.render().el);
  },
  admin_dashboards_show: function(id) {
    var dashboard;
    $('#home_link').removeClass('active');
    $('#admin_link').addClass('active');
    $('#main').empty();
    dashboard = new Dashboard({
      id: id
    });
    return dashboard.fetch({
      success: function(model, resp) {
        var showView;
        showView = new AdminDashboardShowView({
          model: model
        });
        return $('#main').append(showView.render().el);
      },
      error: function() {
        return $('#main').text("cant find");
      }
    });
  }
});

$(function() {
  window.BstatsFrontendApp = new BstatsFrontend();
  return Backbone.history.start();
});
