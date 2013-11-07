/* based on code from Jack Moore: http://www.jacklmoore.com/notes/jquery-modal-tutorial/ */
var modal = (function(){
  var method = {}, $overlay, $modal, $content, $close;
  method.center = function () {
    var top, left;
    top = Math.max($(window).height() - $modal.outerHeight(), 0) / 2;
    left = Math.max($(window).width() - $modal.outerWidth(), 0) / 2;
    $modal.css({
      top:top + $(window).scrollTop(),
      left:left + $(window).scrollLeft()
    });
  };
  method.open = function (settings) {
    $content.empty().append(settings.content);
    $modal.css({
      width: settings.width || 'auto',
      height: settings.height || 'auto'});
    method.center();
    $(window).bind('resize.modal', method.center);
    $modal.show();
    $overlay.show();
  };
  method.close = function () {
    $modal.hide();
    $overlay.hide();
    $content.empty();
    $(window).unbind('resize.modal');
  };

  $overlay = $('<div id="mo-container-overlay"></div>');
  $modal = $('<div id="mo-container-modal"></div>');
  $content = $('<div id="mo-container-content"></div>');
  $close = $('<a id="mo-container-close" href="#">close</a>');

  $modal.hide();
  $overlay.hide();
  $modal.append($content, $close);

  $(document).ready(function(){$('body').append($overlay, $modal);});
  $close.click(function(e){e.preventDefault(); method.close();});
  return method;
}());
