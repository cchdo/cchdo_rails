var mmOpenContainer = null;
var mmOpenMenus = null;
var mmHideMenuTimer = null;

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
		for(var i in mmOpenMenus) {
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
		for(var i in mmOpenMenus) {
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