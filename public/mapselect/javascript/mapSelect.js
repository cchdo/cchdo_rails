/* Mapselect.js
Please set the variables when initializing the map or ELSE! */

/* GLOBALS */
var LOADING_IMAGE = "<img id=\"loading\" src=\"images/loading.gif\" />";
var MAP_SELECT_URL = "http://watershed.ucsd.edu/map_select?";
var CRUISE_INFO_URL = "http://watershed.ucsd.edu/map_select/cruise_html?expocodes=";
var CRUISE_TABLE_ID = "cruise_table";
var MIN_TIME = "1980";
var MAX_TIME = "2008";

var map;
var selectCtrl;

var sw_lat_box, sw_lng_box, ne_lat_box, ne_lng_box;
var min_time, max_time;

// markings
var expocodes;
var selectedTracks;
var markers = {};
var watchMin = null;
var cruiseTable;

// Setup station icon
var icon = new GIcon(G_DEFAULT_ICON, "images/dot.png");
icon.shadow = "";
icon.iconSize = new GSize(3, 3);
icon.shadowSize = new GSize(0, 0);
icon.iconAnchor = new GPoint(0, 0);

/* EVENT HANDLING */
function formChange() {
	sanitizeSelection();
	markSelection();
}

function formSelect() {
	formChange();
	getTracks();
}

/* VALIDATION */

function sanitizeSelection() {
	//var sw_lat = parseFloat(sw_lat_box.value);
	//var ne_lat = parseFloat(ne_lat_box.value);
	//var sw_lng = parseFloat(sw_lng_box.value);
	//var ne_lng = parseFloat(ne_lng_box.value);
	//do normal compare
	//if (sw_lat > ne_lat) {
	//	var tmp = sw_lat_box.value;
	//	sw_lat_box.value = ne_lat_box.value;
	//	ne_lat_box.value = tmp;
	//}
	//if (sw_lng > ne_lng) {
	//	var tmp = sw_lng_box.value;
	//	sw_lng_box.value = ne_lng_box.value;
	//	ne_lng_box.value = tmp;
	//}
	if (parseInt(max_time.value) < parseInt(min_time.value)) {
		var tmp = min_time.value;
		min_time.value = max_time.value;
		max_time.value = tmp;
	}
	if (parseInt(min_time.value) < parseInt(MIN_TIME)) {
		min_time.value = MIN_TIME;
	}
	if (parseInt(max_time.value) > parseInt(MAX_TIME)) {
		max_time.value = MAX_TIME;
	}
}

function setSWBox(latlng) {
	sw_lat_box.value = latlng.lat();
	sw_lng_box.value = latlng.lng();
}

function setNEBox(latlng) {
	ne_lat_box.value = latlng.lat();
	ne_lng_box.value = latlng.lng();
}

function markSelection() {
	ne = new GLatLng(ne_lat_box.value, ne_lng_box.value);
	sw = new GLatLng(sw_lat_box.value, sw_lng_box.value);
	selectCtrl.unmark_();
	selectCtrl.mark_(new GLatLngBounds(sw, ne));
	recenter();
}

/* AJAX */

/**
Takes list of tracks in format:
  [Expocode]
  lat lon
  ... ...
@return [expocode: [GLatLng, ...], ...].
*/
function parseTracks(input){
	var strs = input.split("\n");
	var tracks = [];
	var coords = [];
	for (var str in strs) {
		var line = strs[str];
		if (line.charAt(0) == "[") {
			coords = [];
			tracks[line.slice(1, -1)] = coords;
			tracks.length++;
		}
		else if (line.length > 0) {
			var coord = line.split(" ");
			coords.push(new GLatLng(coord[0], coord[1]));
		}
	}
	return tracks;
}

function gotTracks(response) {
	selectedTracks = parseTracks(response);
	if (selectedTracks.length > 0) {
		expocodes = [];
		for (var expocode in selectedTracks) {
			expocodes.push(expocode);
		}
		getCruiseInfo(expocodes);
	}
	else {
		cruiseTable.innerHTML = "<tr>We do not have records of cruises in that selection.</tr>";
	}
}

/* MARKING */

function recenter() {
//	map.panTo(selectCtrl.globals.marker.getBounds().getCenter());
	map.setCenter(selectCtrl.globals.marker.getBounds().getCenter());
}

function clearMarks() {
	for(var expocode in markers) {
		unmarkCruise(expocode);
	}
	markers = {};
}

function unmarkCruise(expocode) {
	map.removeOverlay(markers[expocode].line);
	map.removeOverlay(markers[expocode].hlline);
	for (var station in markers[expocode].stations) {
		map.removeOverlay(markers[expocode].stations[station]);
	}
	markers[expocode] = null;
}

function hlCruise(expocode) {
	var cruise = markers[expocode];
	showCruiseInfo(expocode);
	cruise.line.hide();
	cruise.hlline.show();
}

function nohlCruise(expocode) {
	var cruise = markers[expocode];
	hideCruiseInfo(expocode);
	cruise.hlline.hide();
	cruise.line.show();
}

function showCruiseInfo(expocode) {
	markers[expocode].stations[0].openInfoWindowHtml("<table>" + document.getElementById(expocode).innerHTML + "</table>");
}

function hideCruiseInfo(expocode) {
	markers[expocode].stations[0].closeInfoWindow();
}

function drillDownCruise(expocode) {
	hlCruise(expocode); 
	document.getElementById(expocode).className = document.getElementById(expocode).className.replace("_active", "") + "_active";
	for (var expocode2 in markers) {
		if (expocode2 != expocode) {
			nohlCruise(expocode2);
			document.getElementById(expocode2).className = document.getElementById(expocode2).className.replace("_active", "");
		}
	}
}

function markCruise(expocode, coords) {
	var stations = [];
	var markerOpts = {icon: icon, clickable: false};
	for (var coord in coords) {
		var marker = new GMarker(coords[coord], markerOpts);
		stations.push(marker);
		map.addOverlay(marker);
	}
	var line = new GPolyline(coords, "#00aa00", 3, 1);
	var hlline = new GPolyline(coords, "#ff8800", 3, 1);
	hlline.hide();
	map.addOverlay(line);
	map.addOverlay(hlline);
	markers[expocode] = {stations: stations, line: line, hlline: hlline};

	GEvent.addListener(line, "click", function() {
		drillDownCruise(expocode);
	});

	// In case someone closes window and clicks again while hled
	GEvent.addListener(hlline, "click", function() {
		showCruiseInfo(expocode);
	});

	var domTableRow = document.getElementById(expocode);
	GEvent.addDomListener(domTableRow, "click", function() {
		drillDownCruise(expocode);
	});
}

function markCruises(expo_coords) {
	for (var expocode in expo_coords) {
		markCruise(expocode, expo_coords[expocode]);
	}
}

function getTracks() {
	http = GXmlHttp.create();
	http.onreadystatechange = function() {
		if (http.readyState > 0 && http.readyState < 4) {
			cruiseTable.innerHTML = "Finding cruises that relate ... " + LOADING_IMAGE;
			clearMarks();
		}
		else if (http.readyState == 4) {
			gotTracks(http.responseText);
		}
	}
	var url = MAP_SELECT_URL + "max_coords=" + 20
		+"&sw_lat="+sw_lat_box.value+"&sw_lng="+sw_lng_box.value
		+"&ne_lat="+ne_lat_box.value+"&ne_lng="+ne_lng_box.value
		+"&min_time="+min_time.innerHTML+"&max_time="+max_time.innerHTML;
	http.open("GET", url, true);
	http.send(null);
}

function getCruiseInfo(expocodes) {
	var http = GXmlHttp.create();
	http.onreadystatechange = function() {
		if (http.readyState > 0 && http.readyState < 4) {
			cruiseTable.innerHTML = LOADING_IMAGE;
		}
		else if (http.readyState == 4) {
			cruiseTable.innerHTML = http.responseText;
			sortables_init(); // Reinit sortables
			markCruises(selectedTracks);
		}
	}
	var url = CRUISE_INFO_URL + expocodes;
	http.open("GET", url, true);
	http.send(null);
}

function map_rightclick() {
	//TODO
	alert("You right clicked. That is bad right now!");
	//selectCtrl.setButtonMode_("selecting");
	//selectCtrl.initCover_();
}

function buttonclick_callback(){
	if (watchMin == null) {
		watchMin = GEvent.addListener(map, "mousemove", setSWBox);
	}
	else {
		GEvent.removeListener(watchMin);
		watchMin = null;
	}
}

function dragstart_callback() {
}

function dragging_callback(startX, startY, endX, endY) {
	setSWBox(map.fromContainerPixelToLatLng(new GPoint(startX, endY)));
	setNEBox(map.fromContainerPixelToLatLng(new GPoint(endX, startY)));
}

function dragend_callback(selection) {
	if (watchMin != null) {
		GEvent.removeListener(watchMin);
		watchMin = null;
	}
	var sw = selection.getSouthWest();
	var ne = selection.getNorthEast();
	setSWBox(selection.getSouthWest());
	setNEBox(selection.getNorthEast());
	sanitizeSelection();
	recenter();
	getTracks();
}

/* INIT */

function initDragSelectControl() {
	// TODO double click to select 
	// GEvent.addListener(map, "singlerightclick", map_rightclick);
	var boxStyle = {
		border: "2px solid #ff0000",
		top: "20px"
	};
	var otherOpts = {
		buttonHTML: "<img src=\"images/select_button_off.gif\" />",
		buttonSelectingHTML: "<img src=\"images/select_button_on.gif\" />",
		buttonStartingStyle: {width: '24px', height: '24px'},
		//stickySelectEnabled: true
	};
	var callbacks = {
		buttonclick: buttonclick_callback,
		dragstart: dragstart_callback,
		dragging: dragging_callback,
		dragend: dragend_callback
	};
	return new DragSelectControl(boxStyle, otherOpts, callbacks);
}

function initialize() {
	if (GBrowserIsCompatible()) {
		// DOM references
		map = new GMap2(document.getElementById("map"));
		ne_lat_box = document.getElementById("ne_lat"); 
		ne_lng_box = document.getElementById("ne_lng");
		sw_lat_box = document.getElementById("sw_lat"); 
		sw_lng_box = document.getElementById("sw_lng");
		min_time = document.getElementById("min_time");
		max_time = document.getElementById("max_time");
		cruiseTable = document.getElementById(CRUISE_TABLE_ID).childNodes[3];
		
		map.setCenter(new GLatLng(0, 0), 2);
		map.addOverlay(new LatLonGraticule());
		map.enableScrollWheelZoom();
		
		selectCtrl = initDragSelectControl();
		map.addControl(selectCtrl);
		map.addControl(new GScaleControl());
		map.addControl(new GSmallZoomControl());
		map.addControl(new GMapTypeControl());
		//map.removeMapType(G_HYBRID_MAP);
		map.addMapType(G_PHYSICAL_MAP);
		map.setMapType(G_PHYSICAL_MAP);
		
		// start us off with a sample selection!
		formChange();
		//onSubmit();

		initSlider();
	}
}
