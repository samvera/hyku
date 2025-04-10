// Handles the infinite scrolling of the resource icons in the resource_type_slider

let scrollPosition = 0;

$(document).on('turbolinks:load', function initializeCarousel() {
  const $resourceRow = $('.resource-row');
  const $item = $resourceRow.children();
  const resourceItemWidth = $('.resource-item').width() + 10; // 10px margin

  // Clone first and last items for infinite scrolling
  const $clonesBefore = $item.slice(-6).clone();
  const $clonesAfter = $item.slice(0, 6).clone();

  $resourceRow.prepend($clonesBefore).append($clonesAfter);

  // Adjust the initial scroll position
  scrollPosition = 6 * resourceItemWidth;
  $resourceRow.css('transform', `translateX(-${scrollPosition}px)`);
})

function scrollResources(direction) {
  const $resourceRow = $('.resource-row');
  const totalItems = $resourceRow.children().length;
  const resourceItemWidth = $('.resource-item').width() + 10; // 10px margin

  if (direction === 'previous') {
    scrollPosition -= resourceItemWidth;
  } else if (direction === 'next') {
    scrollPosition += resourceItemWidth;
  }

  $resourceRow.css({
    transition: 'transform 0.3s ease',
    transform: `translateX(-${scrollPosition}px)`
  });

  // Handle looping after the transition
  $resourceRow.on('transitionend', function () {
    if (scrollPosition < 6 * resourceItemWidth) {
      // Reset to the original items at the end of the array
      scrollPosition += (totalItems - 12) * resourceItemWidth;
      $resourceRow.css({
        transition: 'none',
        transform: `translateX(-${scrollPosition}px)`
      });
    } else if (scrollPosition >= (totalItems - 6) * resourceItemWidth) {
      // Reset to the original items at the beginning of the array
      scrollPosition -= (totalItems - 12) * resourceItemWidth;
      $resourceRow.css({
        transition: 'none',
        transform: `translateX(-${scrollPosition}px)`
      });
    }
    // Remove the transitionend listener after execution
    $resourceRow.off('transitionend');
  });
}
