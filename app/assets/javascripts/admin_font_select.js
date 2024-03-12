Blacklight.onLoad(function() {
  if($("#admin_appearance_body_font").length > 0){
    $("#admin_appearance_body_font").fontselect({lookahead: 20});
    $("#admin_appearance_headline_font").fontselect({lookahead: 20});
  }
});
