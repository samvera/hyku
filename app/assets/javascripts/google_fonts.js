$(document).on('turbolinks:load', function() {
  if (location.pathname.match(/admin\/appearance/)) {

    var bodyFontList = $("#admin_appearance_body_font")
    var headlineFontList = $('#admin_appearance_headline_font')

    var selectedBodyFont = bodyFontList.val()
    var selectedHeadlineFont = headlineFontList.val()


    $.ajax({
      url: 'https://www.googleapis.com/webfonts/v1/webfonts?sort=popularity&key=AIzaSyADkETrrqoQWjhved9e09wupS1gJVkyfe4',
      dataType: 'json',
      method: 'GET',
      success: function(data) {
        handleGoogleFonts(bodyFontList, data.items, selectedBodyFont)
        handleGoogleFonts(headlineFontList, data.items, selectedHeadlineFont)
      }
    })
  }
})

function handleGoogleFonts(element, set, selected) {
  let options = []

  for (var i = 0; i < 99; i++) {
    let option = document.createElement('option')

    option.value = `${set[i].family}|${set[i].category}`
    option.text = set[i].family

    if (selected === option.value) {
      options[0] = option
    } else {
      options[i+1] = option
    }
  }

  element.html(options)
}