// themes form
// dynamically loads the theme notes and wireframe to the theme form
Blacklight.onLoad(function() {
  var el = $('#site_home_theme')
  var theme = el.val();
  var themeInfo = el.data('theme-info');
  var assetPath = el.find(':selected').data('image');
  if (typeof theme !== 'undefined' && typeof themeInfo !== 'undefined') {
    var themeData = themeInfo[theme]; 
    themeData['banner_image'] === true ? $('#banner-image-notes').show() : $('#banner-image-notes').hide();
    themeData['home_page_text'] === true ? $('#home-page-text-notes').show() : $('#home-page-text-notes').hide();
    themeData['marketing_text'] === true ? $('#marketing-text-notes').show() : $('#marketing-text-notes').hide();
    $('#wireframe').find("img").attr("src", assetPath); 
  } 

  el.on('change', function() { 
    theme = el.val();
    themeInfo = el.data('theme-info');
    themeData = themeInfo[theme];
    assetPath = el.find(':selected').data('image');
    
    themeData['banner_image'] === true ? $('#banner-image-notes').show() : $('#banner-image-notes').hide();
    themeData['home_page_text'] === true ? $('#home-page-text-notes').show() : $('#home-page-text-notes').hide();
    themeData['marketing_text'] === true ? $('#marketing-text-notes').show() : $('#marketing-text-notes').hide();
    $('#wireframe').find("img").attr("src", assetPath); 
  });
});