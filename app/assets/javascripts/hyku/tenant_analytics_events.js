// OVERRIDE Hyrax v5.0.0 analytics events to include tenant identifier for multi-tenant analytics isolation

// Override the analytics event tracking to include tenant ID
function trackAnalyticsEventsWithTenant(provider) {
  $('span.analytics-event').each(function(){
    var eventSpan = $(this);
    if(provider !== 'ga4') {
      window.trackingTags.analytics().push([window.trackingTags.trackEvent(), eventSpan.data('category'), eventSpan.data('action'), eventSpan.data('name')]);
    } else {
      gtag('event', eventSpan.data('action'), {
        'content_type': eventSpan.data('category'),
        'content_id': eventSpan.data('name')
      });
    }
  });
}

// Override setupTracking to use tenant-aware version
function setupTenantTracking() {
  var provider = $('meta[name="analytics-provider"]').prop('content');
  if (provider === undefined) {
    return;
  }
  window.trackingTags = new TrackingTags(provider);
  trackAnalyticsEventsWithTenant(provider);
}

// Override file download tracking to include tenant
$(document).on('click', '#file_download', function(e) {
  var provider = $('meta[name="analytics-provider"]').prop('content');
  
  if (provider === undefined) {
    return;
  }
  window.trackingTags = new TrackingTags(provider);

  if(provider !== 'ga4') {
    window.trackingTags.analytics().push([trackingTags.trackEvent(), 'file-set', 'file-set-download', $(this).data('label')]);
    window.trackingTags.analytics().push([trackingTags.trackEvent(), 'file-set-in-work', 'file-set-in-work-download', $(this).data('work-id')]);
    $(this).data('collection-ids').forEach(function (collection) {
      window.trackingTags.analytics().push([trackingTags.trackEvent(), 'file-set-in-collection', 'file-set-in-collection-download', collection]);
      window.trackingTags.analytics().push([trackingTags.trackEvent(), 'work-in-collection', 'work-in-collection-download', collection]);
    });
  } else {
    gtag('event', 'file-set-download', { 
      'content_type': 'file-set', 
      'content_id': $(this).data('label')
    });
    gtag('event', 'file-set-in-work-download', { 
      'content_type': 'file-set-in-work', 
      'content_id': $(this).data('work-id')
    });
    $(this).data('collection-ids').forEach(function (collection) {
      gtag('event', 'file-set-in-collection-download', { 
        'content_type': 'file-set-in-collection', 
        'content_id': collection
      });
      gtag('event', 'work-in-collection-download', { 
        'content_type': 'work-in-collection', 
        'content_id': collection
      });
    });
  }
});

// Use tenant-aware tracking
if (typeof Turbolinks !== 'undefined') {
  $(document).on('turbolinks:load', function() {
    setupTenantTracking();
  });
} else {
  $(document).ready(function() {
    setupTenantTracking();
  });
}
