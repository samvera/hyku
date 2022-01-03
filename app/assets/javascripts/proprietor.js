Blacklight.onLoad(function() {
  if($('#account_search_only').length > 0) {
    $('#account_search_only').change(function() {
      if(this.checked) {
        $('#full_account_cross_container').removeClass('hide')
      } else {
        $('#full_account_cross_container').addClass('hide')
      }
    })
  }
})
