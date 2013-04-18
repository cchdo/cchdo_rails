jQuery(function($) {
  // Don't instrument the datacart download list page
  if (window.location.pathname.split('/')[0] == 'datacart') {
    return;
  }
  var datacart_cart = $('#cchdo_datacart');
  var datacart_count = datacart_cart.find('.count');

  function getCartCount() {
    return parseInt(datacart_count.html());
  }
  function setCartCount(count) {
    datacart_count.html(count);
    if (count > 0) {
      datacart_cart.removeClass('hidden');
    } else {
      datacart_cart.addClass('hidden');
    }
  }

  var datacart_links = $('.datacart-icon');
  datacart_links.each(function() {
    var icon = $(this);
    if (icon.hasClass('datacart-cart')) {
      return;
    }
    var link = icon.closest('a');
    if (link.hasClass('datacart-add-cruise') || link.hasClass('datacart-remove-cruise')) {
      return;
    }
    icon.click(function() {
      var parser = document.createElement("A");
      parser.href = link.attr('href');
      if (link.hasClass('datacart-add')) {
        parser.pathname = parser.pathname.replace("remove", "add");
      } else if (link.hasClass('datacart-remove')) {
        parser.pathname = parser.pathname.replace("add", "remove");
      } else {
        return;
      }
      $.get(parser.href, function(data) {
        setCartCount(data.cart_count);
        if (link.hasClass('datacart-add')) {
          link.removeClass('datacart-add').addClass('datacart-remove');
          link.attr('title', link.attr('title').replace('Add to', 'Remove from'));
          icon.html('Remove');
        } else if (link.hasClass('datacart-remove')) {
          link.removeClass('datacart-remove').addClass('datacart-add');
          link.attr('title', link.attr('title').replace('Remove from', 'Add to'));
          icon.html('Add');
        }
      });
      return false;
    });
  });
});
