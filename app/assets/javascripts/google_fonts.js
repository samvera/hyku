$(document).on('turbolinks:load', function() {
  if (location.pathname.match(/admin\/appearance/)) {
    $.ajax({
      url: 'https://www.googleapis.com/webfonts/v1/webfonts?sort=popularity&key=AIzaSyADkETrrqoQWjhved9e09wupS1gJVkyfe4',
      dataType: 'json',
      method: 'GET',
      success: function(data) {
        console.log(data)
        var bodyFontList = $("#admin_appearance_body_font")
        var headlineFontList = $('#admin_appearance_headline_font')
        for (var i = 0; i < 99; i++) {
          var option1 = document.createElement('option')
          option1.value = "'" + data.items[i].family + "', " + data.items[i].category
          option1.text = data.items[i].family
          var option2 = document.createElement('option')
          option2.value = "'" + data.items[i].family + "', " + data.items[i].category
          option2.text = data.items[i].family
          bodyFontList.append(option1)
          headlineFontList.append(option2)
        }
      }
    })
  }
})