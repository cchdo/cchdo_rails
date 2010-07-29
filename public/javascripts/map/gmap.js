//google.load('maps', '2.x');
//Globals
var map;
var ge;
var overlays = [];
var expo_names = [];
var cruise_names = [];
var sw_lat_box, sw_lng_box, ne_lat_box, ne_lng_box;
var min_time, max_time;
var selectRectCtrl, selectCircleCtrl;
var drilled_expocode = '';
var importedMarkers = null;
var importedCircles = [];
var active_str = ' active';

var MIN_TIME = "1975";
var MAX_TIME = "2008";
var EARTH_RADIUS = 6371.01; //km

//markings
var expocodes;
var selectedTracks;
var markers = {};
var cruiseTable;

//station icon
var station_icon = new GIcon();
station_icon.image = '/images/map_search/station_icon.png';
station_icon.iconSize = new GSize(32, 32);
station_icon.shadowSize = new GSize(0, 0);
station_icon.iconAnchor = new GPoint(0, 32);
station_icon.infoWindowAnchor = new GPoint(0, 0);
var station_marker = {icon: station_icon, clickable: false};

//cruise start icon
var cruise_start_icon = new GIcon(G_DEFAULT_ICON, "/images/map_search/cruise_start_icon.png");
cruise_start_icon.shadow = "";
cruise_start_icon.iconSize = new GSize(24, 12);
cruise_start_icon.shadowSize = new GSize(0, 0);
cruise_start_icon.iconAnchor = new GPoint(12, 12);
var cruise_start_marker = {icon: cruise_start_icon};

function loadmap() { 
  if (GBrowserIsCompatible()) { 
    map = new GMap2($("map"));
    selectRectCtrl = initDragSelectRectControl();
    selectCircleCtrl = initDragSelectCircleControl();
    map.addControl(new GSmallZoomControl());
    map.addControl(new GMenuMapTypeControl());
    map.addControl(new GScaleControl());
    map.addControl(selectRectCtrl);
    map.addControl(selectCircleCtrl);
    map.enableContinuousZoom();
    map.enableScrollWheelZoom();
    map.setCenter(new GLatLng(0, 0), 3);
    map.addMapType(G_SATELLITE_3D_MAP);
    map.addMapType(G_PHYSICAL_MAP);
    map.setMapType(G_PHYSICAL_MAP);
    map.addOverlay(new LatLonGraticule());
    map.getEarthInstance(init_ge);

    ne_lat_box = $('ne_lat'); 
    ne_lng_box = $('ne_lng');
    sw_lat_box = $('sw_lat'); 
    sw_lng_box = $('sw_lng');
    circle_center_lat_box = $('circle_center_lat'); 
    circle_center_lng_box = $('circle_center_lng');
    circle_radius_box = $('circle_radius');
    min_time = $('min_time');
    max_time = $('max_time');

    GEvent.addDomListener($('map_search'), 'click', setSearchBoxActive);
    GEvent.addDomListener($('rectangle_control'), 'click', setRectangleActive);
    GEvent.addDomListener($('circle_control'), 'click', setCircleActive);
    GEvent.addDomListener($('import_control'), 'click', setImportActive);

    rectangleSelectionChange(); //sample

    //gescreenoverlay_rectcontrol();
    //http://earth-api-samples.googlecode.com/svn/trunk/demos/draw/index.html
  }
}


var KMLMap = {
  cruises: {},
  Cruise: function() {
    this.track = null;
    this.start = null;
    this.stations = [];
  },
  hlrow: null,
  hlcruise: null
};

KMLMap.importKML = function(kml) {
  clearMarkers();
  var geoxml = new GGeoXml(kml);
  GEvent.addListener(map, 'addoverlay', function(overlay) { 
    //console.log(overlay); Do more for these
    if (overlay.name != null && overlay.name != 'Search Selection') {
      var ids = overlay.name.split(' ');
      var expo = ids[0], type = ids[1];
      if (KMLMap.cruises[expo] == null) { KMLMap.cruises[expo] = new KMLMap.Cruise(); }
      var cruise = KMLMap.cruises[expo];
      if (type == 'track') {
        cruise.track = overlay;
      } else if (type == 'start') {
        cruise.start = overlay;
      } else if (type == 'station') {
        cruise.stations.push(overlay);
      }
    }
  });
  GEvent.addListener(geoxml, 'load', function() {
    $('cruise_table_div').innerHTML = '<table id="cruise_table"><tr><th>(Line) Expocode</th><th>Ship</th><th>Country</th><th>PI</th><th>Begin Date</th></tr></table>';
    var table = $('cruise_table');
    var toggle = false;
    for (expo in KMLMap.cruises) {
      var cruise = KMLMap.cruises[expo];
      var row = table.insertRow(-1);
      var info = cruise.start.description.split(',');
      var link = document.createElement('a');
      link.href='/search?ExpoCode="'+expo+'"'
      link.appendChild(document.createTextNode(expo));
      row.insertCell(-1).appendChild(link);
      row.insertCell(-1).appendChild(document.createTextNode(info[0]));
      row.insertCell(-1).appendChild(document.createTextNode(info[1]));
      row.insertCell(-1).innerHTML = cruise.track.description;
      row.insertCell(-1).appendChild(document.createTextNode(info[2]));
      row.setAttribute('id', expo);
      (toggle) ? row.className = '_odd' : row.className = '_even';
      toggle = !toggle;
      KMLMap.installListeners(row, cruise);
    }
  });
  map.addOverlay(geoxml);
}

KMLMap.installListeners = function(row, cruise) {
  cruise.tableListener = GEvent.addDomListener(row, 'click', function() { KMLMap.hl(row, cruise); });
  cruise.startListener = GEvent.addListener(cruise.start, 'click', function() { KMLMap.hl(row, cruise); });
}

KMLMap.hl = function(row, cruise) {
  if (this.hlrow) { 
    if (this.hlrow == row) { return; }
    this.unhl(this.hlrow, this.hlcruise);
  }
  cruise.track.color = '#f6ff00';
  cruise.track.weight = 4;
  cruise.track.redraw(true);
  row.className = row.className.replace(active_str, '') + active_str;
  this.hlrow = row;
  this.hlcruise = cruise;
}

KMLMap.unhl = function(row, cruise) {
  cruise.track.color = '#06ff00';
  cruise.track.weight = 2;
  cruise.track.redraw(true);
  row.className = row.className.replace(active_str, '');
}

function init_ge(instance) {
  ge = instance;
  if (ge != null) {
    var geopts = ge.getOptions();
    geopts.setGridVisibility(true);
    geopts.setAtmosphereVisibility(false);
  }
}

function initDragSelectRectControl() {
  var boxStyle = {
  border: "2px solid #ff0000",
  top: "20px"
  };
  var otherOpts = {
    buttonHTML: '<img src="images/select_button_off.gif" />',
    buttonSelectingHTML: '<img src="images/select_button_on.gif" />',
    buttonStartingStyle: {width: '24px', height: '24px'},
  };
  var hooks = {
    buttonclick: rect_buttonclick_hook,
    dragging: rect_dragging_hook,
    dragend: rect_dragend_hook
  };
  return new DragSelectRectControl(boxStyle, otherOpts, hooks);
}

function initDragSelectCircleControl() {
  var boxStyle = {
    border: "2px solid #00ffff",
    top: "20px"
  };
  var otherOpts = {
    buttonHTML: '<img src="images/select_circle_button_off.gif" />',
    buttonSelectingHTML: '<img src="images/select_circle_button_on.gif" />',
    buttonStartingStyle: {width: '24px', height: '24px'},
  };
  var hooks = {
    buttonclick: circle_buttonclick_hook,
    dragstart: circle_dragstart_hook,
    dragging: circle_dragging_hook,
    dragend: circle_dragend_hook
  };
  return new DragSelectCircleControl(boxStyle, otherOpts, hooks);
}

/* ge screen overlay */
function gescreenoverlay_rectcontrol() {
	var screenOverlay = ge.createScreenOverlay('');
	screenOverlay.setIcon(ge.createIcon(''));
	screenOverlay.getIcon().
		  setHref("http://www.google.com/intl/en_ALL/images/logo.gif");

	// Set screen position in pixels
	screenOverlay.getOverlayXY().setXUnits(ge.UNITS_PIXELS);
	screenOverlay.getOverlayXY().setYUnits(ge.UNITS_PIXELS);
	screenOverlay.getOverlayXY().setX(400);
	screenOverlay.getOverlayXY().setY(200);
	
	// Rotate around object's center point
	screenOverlay.getRotationXY().setXUnits(ge.UNITS_FRACTION);
	screenOverlay.getRotationXY().setYUnits(ge.UNITS_FRACTION);
	screenOverlay.getRotationXY().setX(0.5);
	screenOverlay.getRotationXY().setY(0.5);
	
	// Set object's size in pixels
	screenOverlay.getSize().setXUnits(ge.UNITS_PIXELS);
	screenOverlay.getSize().setYUnits(ge.UNITS_PIXELS);
	screenOverlay.getSize().setX(300);
	screenOverlay.getSize().setY(75);
	
	// Rotate 45 degrees
	screenOverlay.setRotation(45);
	
	ge.getFeatures().appendChild(screenOverlay);

	var overlay = ge.createScreenOverlay('');
	overlay.setIcon(ge.createIcon(''));
	overlay.getIcon().setHref('http://ushydro.ucsd.edu:3000/images/select_button_off.gif');
	overlay.getOverlayXY().setXUnits(ge.UNITS_PIXELS);
	overlay.getOverlayXY().setYUnits(ge.UNITS_PIXELS);
	overlay.getOverlayXY().setX(300);
	overlay.getOverlayXY().setY(300);
	overlay.getSize().setXUnits(ge.UNITS_PIXELS);
	overlay.getSize().setYUnits(ge.UNITS_PIXELS);
	overlay.getSize().setX(20);
	overlay.getSize().setY(20);
	ge.getFeatures().appendChild(overlay);
}

/* EVENT HANDLING */

function rectangleSelectionChange() {
  setRectangleActive();
  sanitizeRectangle();
  clearMarkers();
  markRectangleSelection();
}

function circleSelectionChange() {
  setCircleActive();
  clearMarkers();
  markCircleSelection();
}

/* SUBMISSION */

function submitImport() {
  setImportActive();
}

function submitSelection() {
  if ($('selection_type').value == 'rectangle') {
    rectangleSelectionChange();
  } else if ($('selection_type').value == 'circle') {
    circleSelectionChange();
  }
}

function submitSearch() {
  setSearchBoxActive();
  clearMarkers();
  map.setCenter(new GLatLng(0, 0), 1);
}

/* VALIDATION */

function sanitizeRectangle() { /* Done in controller */ }

function sanitizeTime() {
  if (parseInt(max_time.value) < parseInt(min_time.value)) {
    var tmp = min_time.value;
    min_time.value = max_time.value;
    max_time.value = tmp;
    alert('Swapped min time with max time because the values you entered were not min/max.');
  }
  if (parseInt(min_time.value) < parseInt(MIN_TIME)) { min_time.value = MIN_TIME; }
  if (parseInt(max_time.value) > parseInt(MAX_TIME)) { max_time.value = MAX_TIME; }
}

/* SETTING */

function setSWBox(latlng) { sw_lat_box.value = latlng.lat(); sw_lng_box.value = latlng.lng(); }
function setNEBox(latlng) { ne_lat_box.value = latlng.lat(); ne_lng_box.value = latlng.lng(); }
function setCircleCenterBox(latlng) { circle_center_lat_box.value = latlng.lat(); circle_center_lng_box.value = latlng.lng(); }

function setSearchBoxActive() {
  $('map_search').style.background = '#aaaaff';
  $('circle_control').style.background = '#ffdddd';
  $('rectangle_control').style.background = '#ffdddd';
  $('import_control').style.background = '#ddffdd';
  clearMarkers();
}

function setCircleActive() {
  $('selection_type').value = 'circle';
  $('circle_control').style.background = '#ffaaaa';
  $('map_search').style.background = '#ddddff';
  $('rectangle_control').style.background = '#ffdddd';
  $('import_control').style.background = '#ddffdd';
  clearMarkers();
  markCircleSelection();
}

function setRectangleActive() {
  $('selection_type').value = 'rectangle';
  $('rectangle_control').style.background = '#ffaaaa';
  $('map_search').style.background = '#ddddff';
  $('circle_control').style.background = '#ffdddd';
  $('import_control').style.background = '#ddffdd';
  clearMarkers();
  markRectangleSelection();
}

function setImportActive() {
  $('map_search').style.background = '#ddddff';
  $('circle_control').style.background = '#ffdddd';
  $('rectangle_control').style.background = '#ffdddd';
  $('import_control').style.background = '#aaffaa';
  clearMarkers();
}

/* MARKING */

function markRectangleSelection() {
  selectRectCtrl.unmark_();
  selectRectCtrl.mark_(new GLatLngBounds(new GLatLng(parseFloat(sw_lat_box.value), parseFloat(sw_lng_box.value)), new GLatLng(parseFloat(ne_lat_box.value), parseFloat(ne_lng_box.value))));
}

function markCircleSelection() {
  selectCircleCtrl.unmark_();
  selectCircleCtrl.redraw(new GLatLng(parseFloat(circle_center_lat_box.value), parseFloat(circle_center_lng_box.value)), parseFloat(circle_radius_box.value));
}

function recenter() {
  if ($('selection_type').value == 'rectangle') {
    map.setCenter(selectRectCtrl.globals.marker.getBounds().getCenter());
  } else if ($('selection_type').value == 'circle') {
    map.setCenter(selectCircleCtrl.globals.center);
  }
}

function clearMarkers() {
  markers = {};
  drilled_expocode = '';
  map.clearOverlays();
  map.addOverlay(new LatLonGraticule());
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
  cruise.hlline.show();
  cruise.line.hide();
}

function nohlCruise(expocode) {
  var cruise = markers[expocode];
  cruise.line.show();
  cruise.hlline.hide();
}

function drillDownCruise(expocode) {
  /* don't drill self again */
  if(expocode == drilled_expocode) { return; }

  hlCruise(expocode);

  var polyline = markers[expocode].hlline;
  for (var vertex = 1; vertex < polyline.getVertexCount(); vertex++) {
    var marker = new GMarker(polyline.getVertex(vertex), station_marker);
    markers[expocode].stations.push(marker);
    map.addOverlay(marker);
  }

  $(expocode).className = $(expocode).className.replace(active_str, '') + active_str;

  if (drilled_expocode != '') {
    nohlCruise(drilled_expocode);
    $(drilled_expocode).className = $(drilled_expocode).className.replace(active_str, '');

    drilled_stations = markers[drilled_expocode].stations;
    for (var vertex = 1; vertex < drilled_stations.length; vertex++) {
      map.removeOverlay(drilled_stations[vertex]);
    }
  }
  drilled_expocode = expocode;
}

function markCruise(expocode, coords) {
  var stations = [];
  var marker = new GMarker(coords[0], cruise_start_marker);
  stations.push(marker);
  map.addOverlay(marker);

  var line = new GPolyline(coords, '#00aa00', 2, 1);
  var hlline = new GPolyline(coords, '#ff8800', 2, 1);
  hlline.hide();
  map.addOverlay(line);
  map.addOverlay(hlline);
  markers[expocode] = {stations: stations, line: line, hlline: hlline};

  GEvent.addListener(markers[expocode].stations[0], "click", function() {
    drillDownCruise(expocode);
  });

  var domTableRow = $(expocode);
  GEvent.addDomListener(domTableRow, 'click', function() {
    drillDownCruise(expocode);
  });
}

function markCruises(expo_coords) {
  for (var expocode in expo_coords) {
    markCruise(expocode, expo_coords[expocode]);
  }
}

function markImport(latlngs, radius) {
  if (importedMarkers != null) {
    importedMarkers.clearMarkers();
    clearMarkers();
  } else {
    importedMarkers = new MarkerManager(map);
  }
  while (importedCircles.length > 0) {
    map.removeOverlay(importedCircles.pop());
  }
  for (var i=0; i < latlngs.length; i++) {
    importedMarkers.addMarker(new GMarker(latlngs[i], station_marker), 0, 17);
    importedCircles.push(drawCircle(latlngs[i], radius, "#88ff88"));
  }
  importedMarkers.refresh();
}

function drawCircle(center, radius, polyColor) {
  var arclen = radius / EARTH_RADIUS;
  var deltalng = Math.acos((Math.cos(arclen) - Math.pow(Math.sin(center.latRadians()), 2)) / Math.pow(Math.cos(center.latRadians()), 2));

  var outer = new GLatLng(center.lat(), (center.lngRadians() + deltalng) * 180 / Math.PI);
  var projection = map.getCurrentMapType().getProjection();
  var zoom = map.getZoom();
  var center_pt = projection.fromLatLngToPixel(center, zoom);
  var outer_pt = projection.fromLatLngToPixel(outer, zoom);
  var circle_radius = Math.sqrt(Math.pow((outer_pt.x - center_pt.x), 2) + Math.pow((outer_pt.y - center_pt.y), 2));
  
  var polyPoints = Array();
  var polyNumSides = 20;
  var polySideLength = 18;
  
  for (var a = 0; a <= polyNumSides; a++) {
    var aRad = polySideLength*a*(Math.PI/180);
    var pixelX = center_pt.x + circle_radius * Math.cos(aRad);
    var pixelY = center_pt.y + circle_radius * Math.sin(aRad);
    var polyPoint = projection.fromPixelToLatLng(new GPoint(pixelX,pixelY),zoom);
    polyPoints.push(polyPoint);
  }
  var circle = new GPolygon(polyPoints,polyColor,2,.5,polyColor,.5);
  map.addOverlay(circle);
  return circle;
}

/*HOOKS*/

var watchRectMin = null;

function rect_buttonclick_hook(){
  // keep updating the form boxes with the moving coordinates
  if (watchRectMin == null) {
    watchRectMin = GEvent.addListener(map, "mousemove", setSWBox);
  }
  else {
    GEvent.removeListener(watchRectMin);
    watchRectMin = null;
  }
  setRectangleActive();
}

function rect_dragging_hook(startX, startY, endX, endY) {
  setSWBox(map.fromContainerPixelToLatLng(new GPoint(startX, endY)));
  setNEBox(map.fromContainerPixelToLatLng(new GPoint(endX, startY)));
}

function rect_dragend_hook(selection) {
  if (watchRectMin != null) {
    GEvent.removeListener(watchRectMin);
    watchRectMin = null;
  }
  setSWBox(selection.getSouthWest());
  setNEBox(selection.getNorthEast());
  recenter();
  document.selection.onsubmit();
}

var watchCenter = null;

function circle_buttonclick_hook(dragginOn) {
  // keep updating the form boxes with the moving coordinates
  if (watchCenter == null) {
    watchCenter = GEvent.addListener(map, "mousemove", setCircleCenterBox);
  }
  else {
    GEvent.removeListener(watchCenter);
    watchCenter = null;
  }
}

function circle_dragstart_hook(center) {
  if (watchCenter != null) {
    GEvent.removeListener(watchCenter);
    watchCenter = null;
  }
  setCircleActive();
  setCircleCenterBox(center);
}

function circle_dragging_hook(center, radius) {
  circle_radius_box.value = radius / 1000;
}

function circle_dragend_hook(center, radius) {
  recenter();
  document.selection.onsubmit();
}

function $(id) { return document.getElementById(id); }
