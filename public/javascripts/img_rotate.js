// Rotate banner
var ImgRotate = (function () {
  var style = null;
  var delay = 20000;
  var timer = null;

  var offset = 0;
  var next = 0;
  var height = 125;
  var minoffset = -height * 50;

  var tickDelay = 0;
  var animateTime = 600;
  var startTime = 0;

  var _ = function (domobj) {
    style = domobj.style;

    start();
  };  

  function nextOffset() {
    if (offset < minoffset) {
      offset = -height - 5;
      return 0;
    }
    return offset - height;
  }

  function animate() {
    var now = new Date();
    var elapsed = now - startTime

    offset -= -10.0 * (next - offset) / (animateTime - elapsed);
    if (elapsed >= animateTime) {
      offset = next;
    }
    style.backgroundPosition = ['0 ', offset, 'px'].join('');


    if (offset > next) {
      setTimeout(arguments.callee, tickDelay);
    }
  }

  function start() {
    if (timer) {
      clearTimeout(timer);
      next = nextOffset(offset);
      startTime = new Date();
      animate();
    }
    timer = setTimeout(arguments.callee, delay);
  }

  return _;
})();

new ImgRotate(document.getElementById('picture'));
