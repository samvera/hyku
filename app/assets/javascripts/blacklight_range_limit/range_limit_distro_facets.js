// for Blacklight.onLoad:

/* A custom event "plotDrawn.blacklight.rangeLimit" will be sent when flot plot
   is (re-)drawn on screen possibly with a new size. target of event will be the DOM element
   containing the plot.  Used to resize slider to match. */

Blacklight.onLoad(function () {
  // ratio of width to height for desired display, multiply width by this ratio
  // to get height. hard-coded in for now.
  var display_ratio = 1 / (1.618 * 2); // half a golden rectangle, why not
  var redrawnEvent = "plotDrawn.blacklight.rangeLimit";

  // Facets already on the page? Turn em into a chart.
  $(".range_limit .profile .distribution.chart_js ul").each(function () {
    turnIntoPlot($(this).parent());
  });

  // Add AJAX fetched range facets if needed, and add a chart to em
  $(".range_limit .profile .distribution a.load_distribution").each(
    function () {
      var container = $(this).parent("div.distribution");

      $(container).load($(this).attr("href"), function (response, status) {
        if ($(container).hasClass("chart_js") && status == "success") {
          turnIntoPlot(container);
        }
      });
    }
  );

  // Listen for twitter bootstrap collapsible open events, to render flot
  // in previously hidden divs on open, if needed.
  $("body").on("show.bs.collapse", function (event) {
    // Was the target a .facet-content including a .chart-js?
    var container = $(event.target).filter(".facet-content").find(".chart_js");

    // only if it doesn't already have a canvas, it isn't already drawn
    if (container && container.find("canvas").length == 0) {
      // be willing to wait up to 1100ms for container to
      // have width -- right away on show.bs is too soon, but
      // shown.bs is later than we want, we want to start rendering
      // while animation is still in progress.
      turnIntoPlot(container, 1100);
    }
  });

  // after a collapsible facet contents is fully shown,
  // resize the flot chart to current conditions. This way, if you change
  // browser window size, you can get chart resized to fit by closing and opening
  // again, if needed.

  function redrawPlot(container) {
    if (container && container.width() > 0) {
      // resize the container's height, since width may have changed.
      container.height(container.width() * display_ratio);

      // redraw the chart.
      var plot = container.data("plot");
      if (plot) {
        // how to redraw after possible resize?
        // Cribbed from https://github.com/flot/flot/blob/master/jquery.flot.resize.js
        plot.resize();
        plot.setupGrid();
        plot.draw();
        // plus trigger redraw of the selection, which otherwise ain't always right
        // we'll trigger a fake event on one of the boxes
        var form = $(container)
          .closest(".limit_content")
          .find("form.range_limit");
        form.find("input.range_begin").trigger("change");

        // send our custom event to trigger redraw of slider
        $(container).trigger(redrawnEvent);
      }
    }
  }

  $("body").on("shown.bs.collapse", function (event) {
    var container = $(event.target).filter(".facet-content").find(".chart_js");
    redrawPlot(container);
  });

  // debouce borrowed from underscore
  // Returns a function, that, as long as it continues to be invoked, will not
  // be triggered. The function will be called after it stops being called for
  // N milliseconds. If `immediate` is passed, trigger the function on the
  // leading edge, instead of the trailing.
  debounce = function (func, wait, immediate) {
    var timeout;
    return function () {
      var context = this,
        args = arguments;
      var later = function () {
        timeout = null;
        if (!immediate) func.apply(context, args);
      };
      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) func.apply(context, args);
    };
  };

  $(window).on(
    "resize",
    debounce(function () {
      $(".chart_js").each(function (i, container) {
        redrawPlot($(container));
      });
    }, 350)
  );

  // second arg, if provided, is a number of ms we're willing to
  // wait for the container to have width before giving up -- we'll
  // set 50ms timers to check back until timeout is expired or the
  // container is finally visible. The timeout is used when we catch
  // bootstrap show event, but the animation hasn't barely begun yet -- but
  // we don't want to wait until it's finished, we want to start rendering
  // as soon as we can.
  //
  // We also will
  function turnIntoPlot(container, wait_for_visible) {
    // flot can only render in a a div with a defined width.
    // for instance, a hidden div can't generally be rendered in (although if you set
    // an explicit width on it, it might work)
    //
    // We'll count on later code that catch bootstrap collapse open to render
    // on show, for currently hidden divs.

    // for some reason width sometimes return negative, not sure
    // why but it's some kind of hidden.
    if (container.width() > 0) {
      var height = container.width() * display_ratio;

      // Need an explicit height to make flot happy.
      container.height(height);

      areaChart($(container));

      $(container).trigger(redrawnEvent);
    } else if (wait_for_visible > 0) {
      setTimeout(function () {
        turnIntoPlot(container, wait_for_visible - 50);
      }, 50);
    }
  }

  // Takes a div holding a ul of distribution segments produced by
  // blacklight_range_limit/_range_facets and makes it into
  // a flot area chart.
  function areaChart(container) {
    //flot loaded? And canvas element supported.
    if (domDependenciesMet()) {
      // Grab the data from the ul div
      var series_data = new Array();
      var pointer_lookup = new Array();
      var x_ticks = new Array();
      var min = BlacklightRangeLimit.parseNum(
        $(container).find("ul li:first-child span.from").text()
      );
      var max = BlacklightRangeLimit.parseNum(
        $(container).find("ul li:last-child span.to").text()
      );

      $(container)
        .find("ul li")
        .each(function () {
          var from = BlacklightRangeLimit.parseNum(
            $(this).find("span.from").text()
          );
          var to = BlacklightRangeLimit.parseNum(
            $(this).find("span.to").text()
          );
          var count = BlacklightRangeLimit.parseNum(
            $(this).find("span.count").text()
          );
          var avg = count / (to - from + 1);

          //We use the avg as the y-coord, to make the area of each
          //segment proportional to how many documents it holds.
          series_data.push([from, avg]);
          series_data.push([to + 1, avg]);

          x_ticks.push(from);

          pointer_lookup.push({
            from: from,
            to: to,
            count: count,
            label: $(this).find(".facet_select").text(),
          });
        });
      var max_plus_one =
        BlacklightRangeLimit.parseNum(
          $(container).find("ul li:last-child span.to").text()
        ) + 1;
      x_ticks.push(max_plus_one);

      var plot;
      var config =
        $(container).closest(".facet_limit").data("plot-config") || {};

      try {
        plot = $.plot(
          $(container),
          [series_data],
          $.extend(true, config, {
            yaxis: { ticks: [], min: 0, autoscaleMargin: 0.1 },
            //xaxis: { ticks: x_ticks },
            xaxis: { tickDecimals: 0 }, // force integer ticks
            series: { lines: { fill: true, steps: true } },
            grid: { clickable: true, hoverable: true, autoHighlight: false },
            selection: { mode: "x" },
          })
        );
      } catch (err) {
        alert(err);
      }

      find_segment_for = function_for_find_segment(pointer_lookup);
      var last_segment = null;
      $(container).tooltip({
        placement: "bottom",
        trigger: "manual",
        delay: { show: 0, hide: 100 },
      });

      $(container).bind("plothover", function (event, pos, item) {
        segment = find_segment_for(pos.x);

        if (segment != last_segment) {
          var title =
            find_segment_for(pos.x).label +
            " (" +
            BlacklightRangeLimit.parseNum(segment.count) +
            ")";
          $(container)
            .attr("title", title)
            .tooltip("_fixTitle")
            .tooltip("show");

          last_segment = segment;
        }
      });

      $(container).bind("mouseout", function () {
        last_segment = null;
        $(container).tooltip("hide");
      });
      $(container).bind("plotclick", function (event, pos, item) {
        if (plot.getSelection() == null) {
          segment = find_segment_for(pos.x);
          plot.setSelection(normalized_selection(segment.from, segment.to));
        }
      });
      $(container).bind("plotselected plotselecting", function (event, ranges) {
        if (ranges != null) {
          var from = Math.floor(ranges.xaxis.from);
          var to = Math.floor(ranges.xaxis.to);

          var form = $(container)
            .closest(".limit_content")
            .find("form.range_limit");
          form.find("input.range_begin").val(from);
          form.find("input.range_end").val(to);

          var slider_placeholder = $(container)
            .closest(".limit_content")
            .find("[data-slider-placeholder]");
          if (slider_placeholder) {
            slider_placeholder.slider("setValue", [from, to + 1]);
          }
        }
      });

      var form = $(container)
        .closest(".limit_content")
        .find("form.range_limit");
      form.find("input.range_begin, input.range_end").change(function () {
        plot.setSelection(form_selection(form, min, max), true);
      });
      $(container)
        .closest(".limit_content")
        .find(".profile .range")
        .on("slide", function (event, ui) {
          var values = $(event.target).data("slider").getValue();
          form.find("input.range_begin").val(values[0]);
          form.find("input.range_end").val(values[1]);
          plot.setSelection(
            normalized_selection(values[0], Math.max(values[0], values[1] - 1)),
            true
          );
        });

      // initially entirely selected, to match slider
      plot.setSelection({ xaxis: { from: min, to: max + 0.9999 } });
    }
  }

  // Send endpoint to endpoint+0.99999 to have display
  // more closely approximate limiting behavior esp
  // at small resolutions. (Since we search on whole numbers,
  // inclusive, but flot chart is decimal.)
  function normalized_selection(min, max) {
    max += 0.99999;

    return { xaxis: { from: min, to: max } };
  }

  function form_selection(form, min, max) {
    var begin_val = BlacklightRangeLimit.parseNum(
      $(form).find("input.range_begin").val()
    );
    if (isNaN(begin_val) || begin_val < min) {
      begin_val = min;
    }
    var end_val = BlacklightRangeLimit.parseNum(
      $(form).find("input.range_end").val()
    );
    if (isNaN(end_val) || end_val > max) {
      end_val = max;
    }

    return normalized_selection(begin_val, end_val);
  }

  function function_for_find_segment(pointer_lookup_arr) {
    return function (x_coord) {
      for (var i = pointer_lookup_arr.length - 1; i >= 0; i--) {
        var hash = pointer_lookup_arr[i];
        if (x_coord >= hash.from) return hash;
      }
      return pointer_lookup_arr[0];
    };
  }

  // Check if Flot is loaded, and if browser has support for
  // canvas object, either natively or via IE excanvas.
  function domDependenciesMet() {
    var flotLoaded = typeof $.plot != "undefined";
    var canvasAvailable =
      typeof document.createElement("canvas").getContext != "undefined" ||
      typeof window.CanvasRenderingContext2D != "undefined" ||
      typeof G_vmlCanvasManager != "undefined";

    return flotLoaded && canvasAvailable;
  }
});
