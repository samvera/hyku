// themes form
// dynamically loads the theme notes and wireframe to the theme form
Blacklight.onLoad(function() {
  // home page theme notes and wireframe
  var el = $('#site_home_theme');
  var theme = el.val();
  var themeInfo = el.data('theme-info');
  var assetPath = el.find(':selected').data('image');

  if (typeof theme !== 'undefined' && typeof themeInfo !== 'undefined') {
    var themeData = themeInfo[theme];
    $('#home-theme-notes').html(themeData.notes);
    themeData.banner_image === true ? $('#banner-image-notes').show() : $('#banner-image-notes').hide();
    themeData.home_page_text === true ? $('#home-page-text-notes').show() : $('#home-page-text-notes').hide();
    themeData.marketing_text === true ? $('#marketing-text-notes').show() : $('#marketing-text-notes').hide();
    $('#home-wireframe').find("img").attr("src", assetPath);
  }

  el.on('change', function() {
    theme = el.val();
    themeInfo = el.data('theme-info');
    themeData = themeInfo[theme];
    assetPath = el.find(':selected').data('image');

    $('#home-theme-notes').html(themeData.notes);
    themeData.banner_image === true ? $('#banner-image-notes').show() : $('#banner-image-notes').hide();
    themeData.home_page_text === true ? $('#home-page-text-notes').show() : $('#home-page-text-notes').hide();
    themeData.marketing_text === true ? $('#marketing-text-notes').show() : $('#marketing-text-notes').hide();
    $('#home-wireframe').find("img").attr("src", assetPath);
  });

  // show page theme notes and wireframe
  var showSelect = $('#site_show_theme');
  var showTheme = showSelect.val();
  var showThemeInfo = showSelect.data('theme-info');
  var showAssetPath = showSelect.find(':selected').data('image');

  if (typeof showTheme !== 'undefined' && typeof showThemeInfo !== 'undefined') {
    var showThemeData = showThemeInfo[showTheme];
    $('#show-theme-notes').html(showThemeData.notes);
    $('#show-wireframe').find("img").attr("src", showAssetPath);
  }

  showSelect.on('change', function() {
    showTheme = showSelect.val();
    showThemeInfo = showSelect.data('theme-info');
    showThemeData = showThemeInfo[showTheme];
    showAssetPath = showSelect.find(':selected').data('image');

    $('#show-theme-notes').html(showThemeData.notes);
    $('#show-wireframe').find("img").attr("src", showAssetPath);
  });

  // search page theme wireframes
  var searchSelect = $('#site_search_theme');
  var searchTheme = searchSelect.val();
  var searchAssetPath = searchSelect.find(':selected').data('image');

  if (typeof searchTheme !== 'undefined') {
    $('#search-wireframe').find("img").attr("src", searchAssetPath);
  }

  searchSelect.on('change', function() {
    searchTheme = searchSelect.val();
    searchAssetPath = searchSelect.find(':selected').data('image');

    $('#search-wireframe').find("img").attr("src", searchAssetPath);
  });

});
