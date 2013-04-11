jQuery(function($) {
  // Don't instrument the bulk download list page
  if (window.location.pathname.split('/')[0] == 'bulk') {
    return;
  }
  var bulk_cart = $('#cchdo_bulk');
  var bulk_count = bulk_cart.find('.count');

  function getCartCount() {
    return parseInt(bulk_count.html());
  }
  function setCartCount(count) {
    bulk_count.html(count);
    if (count > 0) {
      bulk_cart.removeClass('hidden');
    } else {
      bulk_cart.addClass('hidden');
    }
  }

  var bulk_links = $('.bulk-icon');
  bulk_links.each(function() {
    var icon = $(this);
    if (icon.hasClass('bulk-cart')) {
      return;
    }
    var link = icon.closest('a');
    if (link.hasClass('bulk-add-cruise') || link.hasClass('bulk-remove-cruise')) {
      return;
    }
    icon.click(function() {
      var parser = document.createElement("A");
      parser.href = link.attr('href');
      if (link.hasClass('bulk-add')) {
        parser.pathname = parser.pathname.replace("remove", "add");
      } else if (link.hasClass('bulk-remove')) {
        parser.pathname = parser.pathname.replace("add", "remove");
      } else {
        return;
      }
      $.get(parser.href, function(data) {
        setCartCount(data.cart_count);
        if (link.hasClass('bulk-add')) {
          link.removeClass('bulk-add').addClass('bulk-remove');
          link.attr('title', link.attr('title').replace('Add to', 'Remove from'));
          icon.html('Remove');
        } else if (link.hasClass('bulk-remove')) {
          link.removeClass('bulk-remove').addClass('bulk-add');
          link.attr('title', link.attr('title').replace('Remove from', 'Add to'));
          icon.html('Add');
        }
      });
      return false;
    });
  });
});
