const analyticsCheckboxHandler = (event) => {
  const analyticsFields = document.getElementById('google-analytics-fields');
  if (analyticsFields) {
    analyticsFields.style.display = event.target.checked ? 'flex' : 'none';
  }
};

const setupAnalyticsToggle = () => {
  const analyticsCheckbox = document.getElementById('account_analytics') ||
                           document.querySelector('input[name="account[analytics]"]');
  const analyticsFields = document.getElementById('google-analytics-fields');

  if (analyticsCheckbox && analyticsFields) {
    // Set initial state
    analyticsFields.style.display = analyticsCheckbox.checked ? 'flex' : 'none';

    // Remove existing listener to avoid duplicates, then add new one
    analyticsCheckbox.removeEventListener('change', analyticsCheckboxHandler);
    analyticsCheckbox.addEventListener('change', analyticsCheckboxHandler);
  }
};

document.addEventListener('DOMContentLoaded', setupAnalyticsToggle);
document.addEventListener('turbolinks:load', setupAnalyticsToggle);
