App.cable.subscriptions.create("NotificationsChannel", {
  received: function(data) {
    let notification = $('.notify_number');
    let countSelector = notification.find('.count');
    let count = parseInt(countSelector.html());
    notification.addClass('label-danger').removeClass('label-default');
    countSelector.html(count + 1);
  }
});
