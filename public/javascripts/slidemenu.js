var slideMenu=function(){
	var sp,st,t,m,sa,l,w,sw,ot;
	return{
		build:function(sm,sw,mt,s,sl,h){
			sp=s; st=sw; t=mt;
			m=document.getElementById(sm);
			sa=m.getElementsByTagName('li');
			l=sa.length; w=m.offsetWidth; sw=w/l;
			ot=Math.floor((w-st)/(l-1)); var i=0;
			for(i;i<l;i++){s=sa[i]; s.style.width=sw+'px'; this.timer(s)}
			if(sl!=null){m.timer=setInterval(function(){slideMenu.slide(sa[sl-1])},t)}
		},
		timer:function(s){s.onclick=function(){clearInterval(m.timer);m.timer=setInterval(function(){slideMenu.slide(s)},t)}},
		slide:function(s){
			var cw=parseInt(s.style.width,'10');
			if(cw<st){
				var owt=0; var i=0;
				for(i;i<l;i++){
					if(sa[i]!=s){
						var o,ow; var oi=0; o=sa[i]; ow=parseInt(o.style.width,'10');
						if(ow>ot){oi=Math.floor((ow-ot)/sp); oi=(oi>0)?oi:1; o.style.width=(ow-oi)+'px'}
						owt=owt+(ow-oi)}}
				s.style.width=(w-owt)+'px';
			}else{clearInterval(m.timer)}
		}
	};
}();

function init() {
  slideMenu.build('sf2',900,10,1,1);
  // Get focus changes so the form slides when tabbed through.
  document.forms[1].addEventListener('focus', function(e) {
    var target = e.target;
    while (!target.id || target.id.substring(0, 4) != 'step') {
      target = target.parentNode;
    }
    slideMenu.slide(target.parentNode);
  }, true);
}
