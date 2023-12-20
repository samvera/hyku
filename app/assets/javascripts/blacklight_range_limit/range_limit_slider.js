// for Blacklight.onLoad:

Blacklight.onLoad(function() {
        
  $(".range_limit .profile .range.slider_js").each(function() {
     var range_element = $(this);
      
     var boundaries = min_max(this);
     var min = boundaries[0];
     var max = boundaries[1];
  
     if (isInt(min) && isInt(max)) {
       $(this).contents().wrapAll('<div style="display:none" />');
       
       var range_element = $(this);
       var form = $(range_element).closest(".range_limit").find("form.range_limit");
       var begin_el = form.find("input.range_begin");
       var end_el = form.find("input.range_end");
  
       var placeholder_input = $('<input type="text" data-slider-placeholder="true" style="width:100%;">').appendTo(range_element);
       
       // make sure slider is loaded
       if (placeholder_input.slider !== undefined) {
        placeholder_input.slider({
          min: min,
          max: max+1,
          value: [min, max+1],
          tooltip: "hide"
        });
  
        // try to make slider width/orientation match chart's
        var container      = range_element.closest(".range_limit");
        var plot           = container.find(".chart_js").data("plot");
        var slider_el      = container.find(".slider");
         
        if (plot && slider_el) { 
          slider_el.width(plot.width());
          slider_el.css("display", "block")
          slider_el.css('margin-right', 'auto');
          slider_el.css('margin-left', 'auto'); 
        }
        else if (slider_el) {
          slider_el.css("width", "100%");
        }
       }
      
       // Slider change should update text input values.
       var parent = $(this).parent();
       var form = $(parent).closest(".limit_content").find("form.range_limit");
       $(parent).closest(".limit_content").find(".profile .range").on("slide", function(event, ui) {
        var values = $(event.target).data("slider").getValue();
        form.find("input.range_begin").val(values[0]);
        form.find("input.range_end").val(values[1]);
       });
     }
  
    begin_el.val(min);
    end_el.val(max);
          
    begin_el.change( function() {
      var val = BlacklightRangeLimit.parseNum($(this).val());
      if ( isNaN(val)  || val < min) {
        //for weird data, set slider at min           
        val = min;
      }
      var values = placeholder_input.data("slider").getValue();
      values[0] = val;
      placeholder_input.slider("setValue", values);
    });
          
    end_el.change( function() {
       var val = BlacklightRangeLimit.parseNum($(this).val());
       if ( isNaN(val) || val > max ) {
         //weird entry, set slider to max
         val = max;
       }
      var values = placeholder_input.data("slider").getValue();
      values[1] = val;
      placeholder_input.slider("setValue", values);
    });    
     
  });
  
  // catch event for redrawing chart, to redraw slider to match width
  $("body").on("plotDrawn.blacklight.rangeLimit", function(event) {
    var area       = $(event.target).closest(".limit_content.range_limit");
    var plot       = area.find(".chart_js").data("plot");
    var slider_el  = area.find(".slider");
  
    if (plot && slider_el) {
        slider_el.width(plot.width());
        slider_el.css("display", "block")
        slider_el.css('margin-right', 'auto');
        slider_el.css('margin-left', 'auto'); 
    }
  });
  
  // returns two element array min/max as numbers. If there is a limit applied,
  // it's boundaries are are limits. Otherwise, min/max in current result
  // set as sniffed from HTML. Pass in a DOM element for a div.range
  // Will return NaN as min or max in case of error or other weirdness. 
  function min_max(range_element) {
     var current_limit =  $(range_element).closest(".limit_content.range_limit").find(".current")
     
     
     
     var min = max = BlacklightRangeLimit.parseNum(current_limit.find(".single").text())
     if ( isNaN(min)) {
       min = BlacklightRangeLimit.parseNum(current_limit.find(".from").first().text());
       max = BlacklightRangeLimit.parseNum(current_limit.find(".to").first().text());
     }
    
     if (isNaN(min) || isNaN(max)) {
        //no current limit, take from results min max included in spans
        min = BlacklightRangeLimit.parseNum($(range_element).find(".min").first().text());
        max = BlacklightRangeLimit.parseNum($(range_element).find(".max").first().text());
     }
     
     return [min, max]
  }
  
  
  // Check to see if a value is an Integer
  // see: http://stackoverflow.com/questions/3885817/how-to-check-if-a-number-is-float-or-integer
  function isInt(n) {
    return n % 1 === 0;
  }
  
  });
  