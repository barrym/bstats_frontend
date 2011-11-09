var BstatsCounterBase, BstatsCounterGraph, BstatsCounterLineGraph, BstatsCounterPie, BstatsCounterText;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

BstatsCounterBase = (function() {

  function BstatsCounterBase(params) {
    this.process_new_data = __bind(this.process_new_data, this);
    this.format_timestamp = __bind(this.format_timestamp, this);    this.counters = params.counters || "all";
    this.timestep = params.timestep;
    this.div_id = params.div_id;
    this.p_top = params.padding_top || 25;
    this.p_right = params.padding_right || 25;
    this.p_bottom = params.padding_bottom || 25;
    this.p_left = params.padding_left || 65;
    this.duration_time = params.duration_time || 500;
    this.update_callback = params.update_callback;
    this.title = params.title;
    this.counter_data = {};
    this.sub_type = params.sub_type;
    this.dateFormatter = d3.time.format("%H:%M:%S");
    this.data_points = this.timestep === 'per_second' ? 300 : 60;
    this.div = d3.select(this.div_id);
    this.w = parseInt(this.div.style('width'));
    this.h = parseInt(this.div.style('height'));
    this.window_width = params.window_width || $(document).width();
    this.window_height = params.window_height || $(document).height();
    this.title_font_size = "" + (Math.round(this.window_height * 0.03)) + "px";
    this.other_font_size = "" + (Math.round(this.window_height * 0.015)) + "px";
    this.p_left = params.padding_left || this.window_width * 0.03;
    this.p_right = params.padding_right || this.window_width * 0.03;
  }

  BstatsCounterBase.prototype.format = function(num) {
    return d3.format(",")(num);
  };

  BstatsCounterBase.prototype.format_timestamp = function(timestamp) {
    var date;
    date = new Date(timestamp * 1000);
    return this.dateFormatter(date);
  };

  BstatsCounterBase.prototype.two_dp = function(num) {
    return this.format(d3.format(".2f")(num));
  };

  BstatsCounterBase.prototype.process_new_data = function(new_data) {
    var _this = this;
    if (this.counters === 'all') {
      this.data_to_process = new_data;
    } else {
      this.data_to_process = new_data.filter(function(e, i, a) {
        return _this.counters.some(function(counter, ei, ea) {
          return counter === e.counter;
        });
      });
    }
    return new_data = null;
  };

  return BstatsCounterBase;

})();

BstatsCounterGraph = (function() {

  __extends(BstatsCounterGraph, BstatsCounterBase);

  function BstatsCounterGraph(params) {
    BstatsCounterGraph.__super__.constructor.call(this, params);
    if (this.title) {
      this.h = this.h * 0.85;
      this.div.append("div").attr("class", "title").style("font-size", this.title_font_size).text(this.title);
    }
    this.vis = this.div.append("svg:svg").attr("width", this.w).attr("height", this.h).append("svg:g");
  }

  return BstatsCounterGraph;

})();

BstatsCounterPie = (function() {

  __extends(BstatsCounterPie, BstatsCounterGraph);

  function BstatsCounterPie(params) {
    this.redraw = __bind(this.redraw, this);
    this.process_new_data = __bind(this.process_new_data, this);    BstatsCounterPie.__super__.constructor.call(this, params);
    this.h = Math.min(this.w, this.h);
    this.w = Math.min(this.w, this.h);
    this.r = params.radius || this.w * 0.45;
    this.inner_title = params.inner_title;
    this.sums = [];
    this.arc = d3.svg.arc().innerRadius(this.r * .5).outerRadius(this.r);
    this.donut = d3.layout.pie().sort(d3.descending).value(function(d) {
      return d.sum;
    });
    this.inner_title_font_size = "" + (Math.round(this.window_height * 0.02)) + "px";
  }

  BstatsCounterPie.prototype.process_new_data = function(new_data) {
    var data, entries, key, keys, new_data_keys, sum, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
    BstatsCounterPie.__super__.process_new_data.call(this, new_data);
    new_data_keys = [];
    _ref = this.data_to_process;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      data = _ref[_i];
      if (!this.counter_data[data.counter]) {
        this.counter_data[data.counter] = d3.range(this.data_points).map(function(x) {
          return 0;
        });
      }
      this.counter_data[data.counter].shift();
      this.counter_data[data.counter].push(data.value);
      new_data_keys.push(data.counter);
    }
    keys = d3.keys(this.counter_data);
    for (_j = 0, _len2 = keys.length; _j < _len2; _j++) {
      key = keys[_j];
      if (new_data_keys.indexOf(key) === -1) delete this.counter_data[key];
    }
    _ref2 = d3.entries(this.counter_data);
    for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
      entries = _ref2[_k];
      sum = d3.sum(entries.value);
      if (sum === 0) {
        delete this.sums[entries.key];
      } else {
        this.sums[entries.key] = {
          counter: entries.key,
          sum: sum
        };
      }
    }
    this.redraw();
    if (this.update_callback) return this.update_callback(this.data_to_process);
  };

  BstatsCounterPie.prototype.redraw = function() {
    var arcs, centre_label, entering_arcs, exiting_arcs, new_label;
    var _this = this;
    arcs = this.vis.selectAll("g.arc").data(this.donut(d3.values(this.sums)));
    entering_arcs = arcs.enter().append("svg:g").attr("class", "arc").attr('fill-rule', 'evenodd').attr("transform", "translate(" + (this.w / 2) + ", " + (this.h / 2) + ")");
    entering_arcs.append("svg:path").attr('d', function(d) {
      return _this.arc(d);
    }).attr('class', function(d) {
      return d.data.counter;
    });
    entering_arcs.append("svg:text").style("font-size", this.other_font_size).attr('transform', function(d) {
      return "translate(" + (_this.arc.centroid(d)) + ")";
    }).attr('text-anchor', 'middle').attr('dy', '.35em').text(function(d) {
      return _this.format(d.value);
    });
    arcs.select("path").transition().ease("bounce").duration(500).attr('d', function(d) {
      return _this.arc(d);
    }).attr('class', function(d) {
      return d.data.counter;
    });
    arcs.select("text").attr('transform', function(d) {
      return "translate(" + (_this.arc.centroid(d)) + ")";
    }).attr('text-anchor', 'middle').attr('dy', '.35em').text(function(d) {
      return _this.format(d.value);
    });
    exiting_arcs = arcs.exit();
    exiting_arcs.select("path").transition().duration(this.duration_time).style("opacity", 0);
    exiting_arcs.remove();
    centre_label = this.vis.selectAll("g.centre_label").data([
      d3.sum(d3.values(this.sums), function(d) {
        return d.sum;
      })
    ]);
    new_label = centre_label.enter().append("svg:g").attr("class", "centre_label").attr("transform", "translate(" + (this.w / 2) + ", " + (this.h / 2) + ")");
    if (this.inner_title) {
      new_label.append("svg:text").style("font-size", this.inner_title_font_size).attr("class", "number").attr('dy', -10).attr("text-anchor", "middle").text(function(d) {
        return _this.format(d);
      });
      new_label.append("svg:text").style("font-size", this.inner_title_font_size).attr('dy', 10).attr("text-anchor", "middle").attr("class", "inner_title").text(this.inner_title);
    } else {
      new_label.append("svg:text").style("font-size", this.inner_title_font_size).attr("class", "number").attr("text-anchor", "middle").text(function(d) {
        return _this.format(d);
      });
    }
    return centre_label.select("text.number").text(function(d) {
      return _this.format(d);
    });
  };

  return BstatsCounterPie;

})();

BstatsCounterLineGraph = (function() {

  __extends(BstatsCounterLineGraph, BstatsCounterGraph);

  function BstatsCounterLineGraph(params) {
    this.redraw = __bind(this.redraw, this);
    this.calculate_scales = __bind(this.calculate_scales, this);
    this.process_new_data = __bind(this.process_new_data, this);
    var _this = this;
    BstatsCounterLineGraph.__super__.constructor.call(this, params);
    this.x_tick_count = params.x_tick_count || Math.round(this.w / 100);
    this.y_tick_count = params.y_tick_count || Math.round(this.h / 40);
    this.count = 0;
    this.x = null;
    this.y = null;
    this.times = [];
    this.xrule_data = [];
    this.high_point = [];
    this.xrule_period = Math.round(this.data_points / this.x_tick_count);
    if (this.window_height < 500) this.stroke_width = "1px";
    this.path = d3.svg.line().x(function(d, i) {
      return _this.x(d.time);
    }).y(function(d) {
      return _this.y(d.value);
    }).interpolate("linear");
  }

  BstatsCounterLineGraph.prototype.process_new_data = function(new_data) {
    var data, key, keys, new_data_keys, new_timestamps, _i, _j, _len, _len2, _ref;
    var _this = this;
    BstatsCounterLineGraph.__super__.process_new_data.call(this, new_data);
    new_data_keys = [];
    new_timestamps = {};
    _ref = this.data_to_process;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      data = _ref[_i];
      if (!this.counter_data[data.counter]) {
        this.counter_data[data.counter] = d3.range(this.data_points).map(function(x) {
          return {
            counter: data.counter,
            time: x,
            value: 0
          };
        });
      }
      this.counter_data[data.counter].shift();
      this.counter_data[data.counter].push({
        counter: data.counter,
        time: data.time,
        value: data.value
      });
      new_data_keys.push(data.counter);
      new_timestamps[data.time] = data.time;
    }
    keys = d3.keys(this.counter_data);
    for (_j = 0, _len2 = keys.length; _j < _len2; _j++) {
      key = keys[_j];
      if (new_data_keys.indexOf(key) === -1) {
        console.log("Removing " + key);
        delete this.counter_data[key];
      }
    }
    keys = null;
    d3.keys(new_timestamps).map(function(timestamp) {
      _this.times.push(timestamp);
      if (_this.times.length > _this.data_points) _this.times.shift();
      _this.count++;
      if (_this.count === _this.xrule_period) {
        _this.xrule_data.push({
          time: timestamp
        });
        if (_this.xrule_data.length === (_this.data_points / _this.xrule_period) + 1) {
          _this.xrule_data.shift();
        }
        return _this.count = 0;
      }
    });
    new_data_keys = null;
    new_timestamps = null;
    this.calculate_scales();
    this.redraw();
    if (this.update_callback) return this.update_callback(this.data_to_process);
  };

  BstatsCounterLineGraph.prototype.calculate_scales = function() {
    var all_data_objects, highest_current_point, max, ymax;
    all_data_objects = d3.merge(d3.values(this.counter_data));
    max = d3.max(all_data_objects, function(d) {
      return d.value;
    });
    if (max === 0) {
      ymax = 10;
    } else {
      ymax = max;
    }
    highest_current_point = d3.first(all_data_objects.filter(function(e, i, a) {
      return e.value === max;
    }));
    this.high_point.shift();
    if (max !== 0) this.high_point.push(highest_current_point);
    this.x = d3.scale.linear().domain([d3.min(this.times), d3.max(this.times)]).range([0 + this.p_left, this.w - this.p_right]);
    return this.y = d3.scale.linear().domain([0, ymax]).range([this.h - this.p_bottom, 0 + this.p_top]);
  };

  BstatsCounterLineGraph.prototype.redraw = function() {
    var entering_high, entering_xrule, entering_yrule, exiting_high, exiting_xrule, exiting_yrule, high, paths, xrule, yrule;
    var _this = this;
    xrule = this.vis.selectAll("g.x").data(this.xrule_data, function(d) {
      return d.time;
    });
    entering_xrule = xrule.enter().append("svg:g").attr("class", "x");
    entering_xrule.append("svg:line").style("shape-rendering", "crispEdges").attr("x1", this.w + this.p_left).attr("y1", this.h - this.p_bottom).attr("x2", this.w + this.p_left).attr("y2", 0 + this.p_top).transition().duration(this.duration_time).ease("bounce").attr("x1", function(d) {
      return _this.x(d.time);
    }).attr("x2", function(d) {
      return _this.x(d.time);
    });
    entering_xrule.append("svg:text").text(function(d) {
      return _this.format_timestamp(d.time);
    }).style("font-size", this.other_font_size).attr("text-anchor", "middle").attr("x", this.w + this.p_left).attr("y", this.h - this.p_bottom).attr("dy", 15).transition().duration(this.duration_time).ease("bounce").attr("x", function(d) {
      return _this.x(d.time);
    });
    xrule.select("line").transition().duration(this.duration_time).ease("linear").attr("x1", function(d) {
      return _this.x(d.time);
    }).attr("x2", function(d) {
      return _this.x(d.time);
    });
    xrule.select("text").transition().duration(this.duration_time).ease("linear").attr("x", function(d) {
      return _this.x(d.time);
    });
    exiting_xrule = xrule.exit();
    exiting_xrule.select("line").transition().duration(this.duration_time).ease("linear").delay(this.duration_time * 0.8).style("opacity", 0);
    exiting_xrule.select("text").transition().duration(this.duration_time * 0.8).ease("linear").delay(this.duration_time).style("opacity", 0);
    exiting_xrule.remove();
    yrule = this.vis.selectAll("g.y").data(this.y.ticks(this.y_tick_count));
    entering_yrule = yrule.enter().append("svg:g").attr("class", "y");
    entering_yrule.append("svg:line").style("shape-rendering", "crispEdges").attr("x1", this.p_left).attr("y1", 0).attr("x2", this.w - this.p_right).attr("y2", 0).transition().duration(this.duration_time).ease("bounce").attr("y1", this.y).attr("y2", this.y);
    entering_yrule.append("svg:text").text(this.y.tickFormat(this.y_tick_count)).style("font-size", this.other_font_size).attr("text-anchor", "end").attr("dx", -5).attr("x", this.p_left).attr("y", 0).transition().duration(this.duration_time).ease("bounce").attr("y", this.y);
    yrule.select("text").transition().duration(this.duration_time).attr("y", this.y).text(this.y.tickFormat(this.y_tick_count));
    yrule.select("line").transition().duration(this.duration_time).attr("y1", this.y).attr("y2", this.y);
    exiting_yrule = yrule.exit();
    exiting_yrule.select("line").transition().duration(this.duration_time).ease("back").attr("y1", 0).attr("y2", 0).style("opacity", 0);
    exiting_yrule.select("text").transition().duration(this.duration_time).ease("back").attr("y", 0).style("opacity", 0);
    exiting_yrule.remove();
    high = this.vis.selectAll("g.high_point").data(this.high_point, function(d) {
      return d.value;
    });
    entering_high = high.enter().append("svg:g").attr("class", "high_point");
    entering_high.append("svg:circle").attr("cx", function(d) {
      return _this.x(d.time);
    }).attr("cy", function(d) {
      return _this.y(d.value);
    }).attr("class", function(d) {
      return d.counter;
    }).attr("r", 3);
    entering_high.append("svg:text").style("font-size", this.other_font_size).attr("x", function(d) {
      return _this.x(d.time);
    }).attr("y", function(d) {
      return _this.y(d.value);
    }).attr("text-anchor", "middle").attr("dy", -10).text(function(d) {
      return _this.format(d.value);
    });
    high.select("circle").attr("class", function(d) {
      return d.counter;
    }).transition().duration(this.duration_time).ease("linear").attr("cx", function(d) {
      return _this.x(d.time);
    }).attr("cy", function(d) {
      return _this.y(d.value);
    });
    high.select("text").transition().duration(this.duration_time).ease("linear").attr("x", function(d) {
      return _this.x(d.time);
    }).attr("y", function(d) {
      return _this.y(d.value);
    });
    exiting_high = high.exit();
    exiting_high.remove();
    paths = this.vis.selectAll("path").data(d3.values(this.counter_data), function(d, i) {
      return i;
    });
    paths.enter().append("svg:path").style('stroke-width', this.stroke_width).attr("d", this.path).attr("class", function(d) {
      return d3.first(d).counter;
    });
    paths.attr("transform", "translate(" + (this.x(this.times[5]) - this.x(this.times[4])) + ")").attr("d", this.path).transition().ease("linear").duration(this.duration_time).attr("transform", "translate(0)");
    return paths.exit().transition().duration(this.duration_time).style("opacity", 0).remove();
  };

  return BstatsCounterLineGraph;

})();

BstatsCounterText = (function() {

  __extends(BstatsCounterText, BstatsCounterBase);

  function BstatsCounterText(params) {
    BstatsCounterText.__super__.constructor.call(this, params);
    this.sums = {};
    this.total = 0;
    this.per_second_average = 0;
    this.per_minute_average = 0;
    this.figure_text_size = "" + (Math.round(this.window_height * 0.1)) + "px";
    this.title_text_size = "" + (Math.round(this.window_height * 0.02)) + "px";
    this.div.append("div").attr("class", "bstats-text-figure");
    this.div.append("div").attr("class", "bstats-text-title").style('font-size', this.title_text_size).text(this.title);
  }

  BstatsCounterText.prototype.process_new_data = function(new_data) {
    var data, entries, key, keys, new_data_keys, sum, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
    BstatsCounterText.__super__.process_new_data.call(this, new_data);
    new_data_keys = [];
    _ref = this.data_to_process;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      data = _ref[_i];
      if (!this.counter_data[data.counter]) {
        this.counter_data[data.counter] = d3.range(this.data_points).map(function(x) {
          return 0;
        });
      }
      this.counter_data[data.counter].shift();
      this.counter_data[data.counter].push(data.value);
      new_data_keys.push(data.counter);
    }
    keys = d3.keys(this.counter_data);
    for (_j = 0, _len2 = keys.length; _j < _len2; _j++) {
      key = keys[_j];
      if (new_data_keys.indexOf(key) === -1) delete this.counter_data[key];
    }
    _ref2 = d3.entries(this.counter_data);
    for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
      entries = _ref2[_k];
      sum = d3.sum(entries.value);
      if (sum === 0) {
        delete this.sums[entries.key];
      } else {
        this.sums[entries.key] = sum;
      }
    }
    this.total = d3.sum(d3.values(this.sums));
    switch (this.timestep) {
      case 'per_second':
        this.per_second_average = this.two_dp(this.total / 300);
        this.per_minute_average = this.two_dp(this.total / 5);
        break;
      case 'per_minute':
        this.per_second_average = this.two_dp(this.total / 3600);
        this.per_minute_average = this.two_dp(this.total / 60);
    }
    return this.redraw();
  };

  BstatsCounterText.prototype.redraw = function() {
    var text;
    text = (function() {
      switch (this.sub_type) {
        case 'total':
          return this.format(this.total);
        case 'per_second_average':
          return this.per_second_average;
        case 'per_minute_average':
          return this.per_minute_average;
        default:
          return "unknown sub_type";
      }
    }).call(this);
    return this.div.select(".bstats-text-figure").style('font-size', this.figure_text_size).text(text);
  };

  return BstatsCounterText;

})();

BstatsCounterGraph = (function() {

  function BstatsCounterGraph(params) {
    switch (params.type) {
      case 'pie':
        params.inner_title = params.title;
        delete params.title;
        return new BstatsCounterPie(params);
      case 'line':
        return new BstatsCounterLineGraph(params);
      case 'text':
        return new BstatsCounterText(params);
      default:
        console.log("unknown bstats type " + params.type);
    }
  }

  return BstatsCounterGraph;

})();
