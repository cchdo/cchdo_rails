// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults




var mmOpenContainer = null;
var mmOpenMenus = null;
var mmHideMenuTimer = null;
var theDays = new Array("SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY");
var theMonths = new Array("JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER");
var theDate = new Date();

function StartTimeout(hideTimeout) {
	mmHideMenuTimer = setTimeout("HideMenus()", hideTimeout);	
}

function HideMenus() {
	ResetTimeout();
	if(mmOpenContainer) {
		var c = document.getElementById(mmOpenContainer);
		c.style.visibility = "inherit";
		mmOpenContainer = null;
	}
	if( mmOpenMenus ) {
		//for(var i in mmOpenMenus) {
		for(var i = 0; i < mmOpenMenus.length; i++) {
			
			var m = document.getElementById(mmOpenMenus[i]);
			m.style.visibility = "hidden";			
		}
		mmOpenMenus = null;
	}
}

function HideSubmenus(menuName) {
	if( mmOpenMenus ) {
		var h = false;
		var c = 0;
		//for(var i in mmOpenMenus) {
		for(var i = 0; i < mmOpenMenus.length; i++) {
		
			if( h ) {
				var m = document.getElementById(mmOpenMenus[i]);
				m.style.visibility = "hidden";
			} else if( mmOpenMenus[i] == menuName ) {
				h = true;
			} else {
				c++;
			}
		}
		mmOpenMenus.length = c+1;
	}
}

function OverMenuItem(menuName, subMenuSuffix) {
	ResetTimeout();
	HideSubmenus(menuName);
	if( subMenuSuffix ) {
		var subMenuName = "" + menuName + "_" + subMenuSuffix;
		ShowSubMenu(subMenuName);
	}
}

function ShowSubMenu(subMenuName) {
	ResetTimeout();
	var e = document.getElementById(subMenuName);
	e.style.visibility = "inherit";
	if( !mmOpenMenus ) {
		mmOpenMenus = new Array;
	}
	mmOpenMenus[mmOpenMenus.length] = "" + subMenuName;
}

function ResetTimeout() {
	if (mmHideMenuTimer) clearTimeout(mmHideMenuTimer);
	mmHideMenuTimer = null;
}

function ShowMenu(containName, menuName, xOffset, yOffset, triggerName) {
	HideMenus();
	ResetTimeout();
	ShowMenuContainer(containName, xOffset, yOffset, triggerName);
	ShowSubMenu(menuName);
}

function ShowMenuContainer(containName, x, y, triggerName) {	
	var c = document.getElementById(containName);
	var s = c.style;
	s.visibility = "inherit";
	
	mmOpenContainer = "" + containName;
}
////////////////////////////////////////////////////
 Ajax.Responders.register({
 onCreate: function(){
   if($('busy') && Ajax.activeRequestCount > 0){
       Effect.Appear('busy', {duration: 0.5, queue: 'end'});
   }
 },
 onComplete: function(){
   if($('busy') && Ajax.activeRequestCount == 0){
     Effect.Fade('busy', {duration: 0.5, queue: 'end'});
   }
 }
});

//function check_files(div){
	//if (!div) return false;
	  //if (typeof div == 'string')
//	    element = document.getElementById('bottle_files');
//	  if (element) element.innerHTML = div+'   ' + element.innerHTML
//	}
//}
//var Alerter = {
//  displayMessage: function(text) {
//    alert(text);
//  }
//}
