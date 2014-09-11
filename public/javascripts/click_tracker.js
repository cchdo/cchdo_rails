jQuery.noConflict();
jQuery(document).ready(function($) {
  return $('#data .box_content .file_type a').click(function(event) {
    var expocode = $(this).attr('expocode');
    var fileType = $(this).attr('file_type');
    var string = '{"expocode":"' + expocode + '", "file_type":"' + fileType + '"}';
    if (expocode) {
      $.ajax({
        url: 'http://hdo.ucsd.edu:60000/',
        type: 'POST',
        dataType: 'json',
        crossDomain: true,
        data: string,
        async: false,
        success: function(response) {console.log(response)},
        error: function() {},
        timeout: 500000
      });
    }
  });
});
