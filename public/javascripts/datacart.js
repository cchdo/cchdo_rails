function make_datacart_links($){
  $('.datacart-link-file-placeholder').each(function(e){
    var path = this.getAttribute('filepath');
    var data_key = 'cchdo_datacart|' + path;
    var data_cart_icon = $('.datacart-icon', this);

    if (data_key in localStorage){
      data_cart_icon.html('Remove');
      $(this).removeClass('datacart-link-file-placeholder').addClass('datacart-remove datacart-link');
      $(this).attr('title', 'Remove data from cart');
      $(this).attr('incart', 'true');
    }else{
      data_cart_icon.html('Add');
      $(this).removeClass('datacart-link-file-placeholder').addClass('datacart-add datacart-link');
      $(this).attr('title', 'Add data to cart');
      $(this).attr('incart', 'false');
    }
  });
    $('.datacart-cruise-placeholder').each(function(e){
      var expocode = $(this).attr('expocode');
      var data_cart_icon = $('.datacart-icon', this);
      if ($('.datacart a[expocode="'+expocode+'"][incart="true"]').length > 0){
        data_cart_icon.html('Remove All');
        $(this).removeClass('datacart-cruise-placeholder').addClass('datacart-remove datacart-cruise datacart-link');
        $(this).attr('title', 'Remove all data from cart');
      } else {
        data_cart_icon.html('Add All');
        $(this).removeClass('datacart-cruise-placeholder').addClass('datacart-add datacart-cruise datacart-link');
        $(this).attr('title', 'Add all data to cart');
      }
    });
  $('.datacart-results-placeholder').each(function(e){
      var data_cart_icon = $('.datacart-icon', this);
      if ($('.datacart').length > 0) {
        if ($('.datacart a[incart="true"]').length > 0){
          data_cart_icon.html('Remove All <span style="display:none" id="working">Working...</span>');
          $(this).removeClass('datacart-results-placeholder').addClass('datacart-remove datacart-results datacart-link');
          $(this).attr('title', 'Remove all data from cart');
        } else {
          data_cart_icon.html('Add All <span style="display:none" id="working">Working...</span>');
          $(this).removeClass('datacart-results-placeholder').addClass('datacart-add datacart-results datacart-link');
          $(this).attr('title', 'Add all data to cart');
        }
      }
    });
}
function empty_datacart(){
  keys = new Array();
  if (window.confirm("This will remove everything in the datacart and cannot be undone")){
  for (var i = 0; i < localStorage.length; i++){
    keys.push(localStorage.key(i));
  }
  for (var i = 0; i < keys.length; i++){
    delete localStorage[keys[i]];
  }
  window.location.reload();
  }

}
function gen_datacart_download_form($){
    var dc_form = $('#datacart_form_placeholder');
    var files = [];
    for (var i = 0; i < localStorage.length; i++){
      var key = localStorage.key(i);
      if (key.indexOf('cchdo_datacart|') == 0){
        filepath = key.split('|')[1];
        files.push(filepath);
      }
      var form = '' + 
                  '<form action="http://cchdo.ucsd.edu/download/download.zip" method="post">' + 
                  '<input type="hidden" name="archive" value="'+files.join(',')+'">' +
                  '<input type="submit" value="Download All Files" class="download">' +
                  '</form>' +
                  '<input type="submit" onclick="empty_datacart();" value="Empty Datacart">';
      dc_form.html(form);
}
}

function gen_datacart_page($){
    var dc = $("#datacart_placeholder");
    //datacart page now needs to be generated
    var dc_content = "<table>";
    var files = [];
    for (var i = 0; i < localStorage.length; i++){
      var key = localStorage.key(i);
      if (key.indexOf('cchdo_datacart|') == 0){
        filepath = key.split('|')[1];
        filename = filepath.split('/');
        filename = filename[filename.length - 1];
        files.push(filepath);
        dc_content = dc_content + '<tr><td><a href="/cruise/'+localStorage[key] +'">'+localStorage[key]+'</a></td><td>'+ filename + '</td><td>'+
          '<a href="javascript:;" class="datacart-link-file-placeholder" expocode="'+localStorage[key]+'" filepath="'+filepath+'" rel=" nofollow"><div class="datacart-icon"></div></a>' +
          '</td></tr>';
      }
      
    }
    dc_content = dc_content + '</table>';
    if (files.length == 0){
    dc_content = "There are no files in the datacart, please visit cruise pages to add files";
    } else{
      gen_datacart_download_form($)
    }
    dc.html(dc_content);
}
jQuery(function($) {
  function supports_html5_storage() {
    try {
      return 'localStorage' in window && window['localStorage'] !== null;
    } catch (e) {
      return false;
    }
  }
  // Don't instrument the datacart download list page. That requires removing
  // list elements and changing page logic.
  if (window.location.pathname.split('/')[1] == 'datacart') {
    gen_datacart_page($);
  }

  if (!supports_html5_storage()){
    return;
  }

  make_datacart_links($);

  var datacart_cart = $('#cchdo_datacart');
  var datacart_count = datacart_cart.find('.count');

  function getCartCount() {
    count = 0;
    for (var i = 0; i < localStorage.length; i++){
      var key = localStorage.key(i);
      if (key.indexOf('cchdo_datacart|') == 0){
        count++;
      }
    }
    return count;
  }
  function setCartCount(count) {
    datacart_count.html(count);
    if (count > 0) {
      datacart_cart.removeClass('hidden');
    } else {
      datacart_cart.addClass('hidden');
    }
  }
  setCartCount(getCartCount());

  function setIconAdd(icon) {
    var link = icon.closest('.datacart-link');
    link.removeClass('datacart-remove').addClass('datacart-add');
    link.attr('title', link.attr('title').replace('Remove', 'Add').replace('from', 'to'));
    icon.html(icon.html().replace('Remove', 'Add'));
  }
  function setIconRemove(icon) {
    var link = icon.closest('.datacart-link');
    link.removeClass('datacart-add').addClass('datacart-remove');
    link.attr('title', link.attr('title').replace('Add', 'Remove').replace('to', 'from'));
    icon.html(icon.html().replace('Add', 'Remove'));
  }

  $('body').delegate('.datacart-icon:not(.datacart-cart)', 'click', function(e) {
    var icon = $(this);
    var link = icon.closest('.datacart-link');
    if (link.hasClass('datacart-results')) {
      $('#working').css('display', 'inline');
      window.setTimeout(function(e){
      if (link.hasClass('datacart-remove')){
        $('.datacart a[incart="true"]').each(function(e){
          $(".datacart-icon", this).click();
        });
        $('.datacart-remove').each(function(e){
          setIconAdd($(this));
        });
      } else{
        $('.datacart a[incart="false"]').each(function(e){
          $(".datacart-icon", this).click();
        });
        $('.datacart-add').each(function(e){
          setIconRemove($(this));
        });
      }
      $('#working').css('display', 'none');
      }, 50);
      return true;
    }
    if (link.hasClass('datacart-cruise')) {
      var expocode = link.attr('expocode');
      if (link.hasClass('datacart-remove')){
        setIconAdd(icon);
        $('.datacart a[expocode="'+expocode+'"][incart="true"]').each(function(e){
          $(".datacart-icon", this).click();
        });
      } else{
        setIconRemove(icon);
        $('.datacart a[expocode="'+expocode+'"][incart="false"]').each(function(e){
          $(".datacart-icon", this).click();
        });
      }
      return true;
    }
    var expocode = link.attr('expocode');
    var path = link.attr('filepath');
    var data_key = 'cchdo_datacart|' + path;
    if (data_key in localStorage){
      setIconAdd(icon);
      delete localStorage[data_key];
      link.attr('incart', 'false');
    } else {
      localStorage[data_key] = expocode;
      setIconRemove(icon);
      link.attr('incart', 'true');
    }
    if (window.location.pathname.split('/')[1] == 'datacart') {
      gen_datacart_download_form($);
    }
    setCartCount(getCartCount());
    return false;
  });
});
