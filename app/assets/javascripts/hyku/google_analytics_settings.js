const analyticsCheckboxHandler = (event) => {
  const analyticsFields = document.getElementById('google-analytics-fields');
  if (analyticsFields) {
    analyticsFields.style.display = event.target.checked ? 'flex' : 'none';
  }
};

const setupAnalyticsToggle = () => {
  // More comprehensive search for the analytics checkbox
  const analyticsCheckbox = document.getElementById('account_analytics') ||
                           document.querySelector('input[name="account[analytics]"]') ||
                           document.querySelector('input[type="checkbox"][id*="analytics"]') ||
                           document.querySelector('input[type="checkbox"][name*="analytics"]');
  const analyticsFields = document.getElementById('google-analytics-fields');

  console.log('Debug - Analytics checkbox found:', !!analyticsCheckbox);
  console.log('Debug - Analytics fields found:', !!analyticsFields);
  
  if (analyticsCheckbox) {
    console.log('Debug - Checkbox ID:', analyticsCheckbox.id);
    console.log('Debug - Checkbox name:', analyticsCheckbox.name);
    console.log('Debug - Checkbox checked:', analyticsCheckbox.checked);
  }

  if (analyticsCheckbox && analyticsFields) {
    // Set initial state
    analyticsFields.style.display = analyticsCheckbox.checked ? 'flex' : 'none';

    // Remove listener to avoid duplicates, then add it.
    analyticsCheckbox.removeEventListener('change', analyticsCheckboxHandler);
    analyticsCheckbox.addEventListener('change', analyticsCheckboxHandler);
    
    console.log('Debug - Event listener attached successfully');
  } else {
    console.log('Debug - Could not find both checkbox and fields');
  }
};

document.addEventListener('DOMContentLoaded', setupAnalyticsToggle);
document.addEventListener('turbolinks:load', setupAnalyticsToggle);
