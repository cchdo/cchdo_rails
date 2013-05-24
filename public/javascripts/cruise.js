jQuery(function($) {
  function getNoteDetail(header) {
    var detail_id = '#' + header.attr('id') + '_detail';
    return $(detail_id);
  }
  $('.note_header').click(function() {
    var detail = getNoteDetail($(this));
    console.log(detail);
    var shown = detail.data('shown');
    if (shown === undefined) {
      shown = true;
    }
    if (shown) {
      detail.data('shown', false);
      detail.hide();
    } else {
      detail.data('shown', true);
      detail.show();
    }
  });
  var toggle_button = $('<button>');
  toggle_button.click(function() {
    if ($(this).data('details')) {
      $(this).data('details', false);
      $(this).html('Show all note details');
      $('.note_header').each(function() {
        getNoteDetail($(this)).data('shown', false).hide();
      });
    } else {
      $(this).data('details', true);
      $(this).html('Hide all note details');
      $('.note_header').each(function() {
        getNoteDetail($(this)).data('shown', true).show();
      });
    }
  });
  // Automatically expand all history notes if sent here with history
  // notes opened
  if (window.location.hash == '#history') {
    toggle_button.data('details', false).click();
  // Automatically expand the one history notes if sent here with one
  // history note opened
  } else if (window.location.hash.indexOf('#note_') > -1) {
    toggle_button.data('details', true).click();
    $(window.location.hash).addClass('active').click();
    $(window.location.hash + '_detail').addClass('active');
  } else {
    toggle_button.data('details', true).click();
  }
  $('#data_access_history').prepend(toggle_button);

  // Clicking on a oneclick textarea should select the whole thing for fast copying
  $('textarea.oneclick').click(function() { $(this).select(); });
});
