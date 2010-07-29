function toggleNext(tag) {
 var next=tag.nextSibling;
 while(next.nodeType != 1) next=next.nextSibling;
 next.style.display=((next.style.display=="none") ? "block" : "none");
}

function getElementsByTagAndClassName(tag,cname) {
 var tags=document.getElementsByTagName(tag);
 var cEls=new Array();
 for (i=0; i<tags.length; i++) {
  var rE = new RegExp("(^|\\s)" + cname + "(\\s|$)");
   if (rE.test(tags[i].className)) {
   cEls.push(tags[i]);
   }
  }
 return cEls;
}

function toggleNextByTagAndClassName(tag,cname) {
 var ccn="clicker";
 clickers=getElementsByTagAndClassName(tag,cname);
 for (i=0; i<clickers.length; i++) {
  clickers[i].className+=" "+ccn;
  clickers[i].onclick=function() {toggleNext(this)}
  toggleNext(clickers[i]);
 }
}

window.onload=function() {toggleNextByTagAndClassName('p','data_history_note')}