/*Graticule; adapted from www.bdcc.co.uk Bill Chadwick 2006 Free for any use*/
function Graticule(sexagesimal) {
    this.sex_ = sexagesimal || false;//default is decimal intervals
}
Graticule.prototype = new GOverlay();
Graticule.prototype.initialize = function(map) {
  this.map_ = map;
  this.divs_ = []; //array for line and label divs
  this.mapPane = this.map_.getPane(G_MAP_MARKER_SHADOW_PANE);
}
Graticule.prototype.copy = function() { return new Graticule(this.sex_); }
Graticule.prototype.remove = function() {
  try{for(var i=0; i<this.divs_.length; i++) this.mapPane.removeChild(this.divs_[i]);} catch(e){}
}
Graticule.prototype.latLngToPixel = function(lat, lng) { return this.map_.fromLatLngToDivPixel(new GLatLng(lat,lng)); }
Graticule.prototype.addDiv = function(div) { this.mapPane.insertBefore(div,null); this.divs_.push(div); }
Graticule.prototype.decToSex = function(d) {
  var degs = Math.floor(d); 
  var mins = ((Math.abs(d)-degs)*60.0).toFixed(2);
  if(mins == "60.00"){ degs += 1.0; mins = "0.00"; }
  return degs + ":" + mins; 
}
Graticule.prototype.makeLabel = function(x, y, text) {
  var d = document.createElement("DIV");
  var s = d.style;
  s.position = "absolute";
  s.left = x.toString() + "px";
  s.top = y.toString() + "px";
  s.color = this.color_;
  s.width = '3em';
  s.fontSize = 'x-small';
  d.innerHTML = text;
  return d;
};

// Redraw the graticule based on the current projection and zoom level
Graticule.prototype.redraw = function(force) {
  this.remove(); //clear old
  this.color_ = this.map_.getCurrentMapType().getTextColor(); //best color for writing on the map

  var bnds = this.map_.getBounds(); //determine graticule interval
  var sw = bnds.getSouthWest(); var ne = bnds.getNorthEast();
  var l = sw.lng(); var b = sw.lat();
  var r = ne.lng(); var t = ne.lat();

  //sanity
  if(b < -90.0) b = -90.0;
  if(t > 90.0) t = 90.0;
  if(l < -180.0) l = -180.0;  
  if(r > 180.0) r = 180.0;
  if(l == r){ l = -180.0; r = 180.0; }
  if(t == b){ b = -90.0; t = 90.0; }

  //grid interval in degrees
  var dLat = this.gridIntervalMins(t-b)/60;
  var dLng = 1/60; 
  if(r>l) dLng *= this.gridIntervalMins(r-l);
  else dLng *= this.gridIntervalMins((180-l)+(r+180));

  //round iteration limits to the computed grid interval
  l = Math.floor(l/dLng)*dLng;
  b = Math.floor(b/dLat)*dLat;
  t = Math.ceil(t/dLat)*dLat;
  r = Math.ceil(r/dLng)*dLng;

  //Sanity
  if(b < -90.0) b = -90;
  if(t > 90.0) t = 90;
  if(l < -180.0) l = -180.0;  
  if(r > 180.0) r = 180.0;
  
  // digits after DP for decimal labels
  var latDecs = this.gridPrecision(dLat);
  var lonDecs = this.gridPrecision(dLng);
  
  this.divs_ = new Array();

  //min and max x and y pixel values for graticule lines
  var pbl = this.latLngToPixel(b,l);
  var ptr = this.latLngToPixel(t,r);
  this.maxX = ptr.x; this.maxY = pbl.y;
  this.minX = pbl.x; this.minY = ptr.y;

  //labels on second column to avoid peripheral controls
  var y = this.latLngToPixel(b+dLat+dLat,l).y + 2;//coord for label
  var lo = l;//copy to save original
  if(r<lo) r += 360.0;

  //lngs
  var crosslng = lo+2*dLng;
  for(; lo<r; lo+=dLng){//lo<r to skip printing 180/-180
    if (lo > 180.0){ r -= 360.0; lo -= 360.0; }	
    var px = this.latLngToPixel(b,lo).x;
    this.addDiv(this.createVLine(px));
    
    var text;
    if(this.sex_) text = this.decToSex(lo);
    else text = lo.toFixed(lonDecs);//only significant digits
    if(lo != crosslng) {
      this.addDiv(this.makeLabel(px+3, y, text));
    } else {
      this.addDiv(this.makeLabel(px+17, y-3, text));
    }
  }
      
  //labels on second row; avoid controls
  var x = this.latLngToPixel(b,l+dLng+dLng).x + 3;
  
  //lats
  var crosslat = b+2*dLat;
  for(; b<=t; b+=dLat){
    var py = this.latLngToPixel(b,l).y;
    if(r <= l) {
      this.addDiv(this.createHLine3(b)); //draw lines across the dateline or world scale zooms
      //console.log('hl#######');
    } else {
      this.addDiv(this.createHLine3(b)); //draw lines across the dateline or world scale zooms
      //this.addDiv(this.createHLine(py));
      //console.log('hl');
    }
    		
    var text;
    if(this.sex_) text = this.decToSex(b);
    else text = b.toFixed(latDecs);//only significant digits
    if(b != crosslat){ 
      this.addDiv(this.makeLabel(x, py+2, text));
    } else {
      this.addDiv(this.makeLabel(x, py+7, text));
    }
  }
}

Graticule.prototype.gridIntervalMins = function(dDeg) {
  if(this.sex_) return this.gridIntervalSexMins(dDeg)
  return this.gridIntervalDecMins(dDeg)
}

//calculate rounded graticule interval in decimals of degrees for supplied lat/lon span
//return is in minutes
Graticule.prototype.gridIntervalDecMins = function(dDeg) {
  var numLines = 10;
  dDeg = Math.ceil(dDeg/numLines*6000)/100;
	if(dDeg <= 0.06) return 0.06;//0.001 degrees
	else if(dDeg <= 0.12) return 0.12;//0.002 degrees
	else if(dDeg <= 0.3) return 0.3;//0.005 degrees
	else if(dDeg <= 0.6) return 0.6;//0.01 degrees
	else if(dDeg <= 1.2) return 1.2;//0.02 degrees
	else if(dDeg <= 3) return 3;//0.05 degrees
	else if(dDeg <= 6) return 6;//0.1 degrees
	else if(dDeg <= 12) return 12;//0.2 degrees
	else if(dDeg <= 30) return 30;//0.5
	else if(dDeg <= 60) return 60;//1
	else if(dDeg <= (60*2)) return 60*2;
	else if(dDeg <= (60*5)) return 60*5;
	else if(dDeg <= (60*10)) return 60*10;
	else if(dDeg <= (60*20)) return 60*20;
	else if(dDeg <= (60*30)) return 60*30;
	else return 60*45;
}

//calculate rounded graticule interval in Minutes for supplied lat/lon span
//return is in minutes
Graticule.prototype.gridIntervalSexMins = function(dDeg) {
  var numLines = 10;
  dDeg = Math.ceil(dDeg/numLines*6000)/100;
  if(dDeg <= 0.01) return 0.01;//minutes 
  else if(dDeg <= 0.02) return 0.02;
  else if(dDeg <= 0.05) return 0.05;
  else if(dDeg <= 0.1) return 0.1;
  else if(dDeg <= 0.2) return 0.2;
  else if(dDeg <= 0.5) return 0.5;
  else if(dDeg <= 1.0) return 1.0;
  else if(dDeg <= 3) return 3;//0.05 degrees
  else if(dDeg <= 6) return 6;//0.1 degrees
  else if(dDeg <= 12) return 12;//0.2 degrees
  else if(dDeg <= 30) return 30;//0.5
  else if(dDeg <= 60) return 60;//1
  else if(dDeg <= (60*2)) return 60*2;
  else if(dDeg <= (60*5)) return 60*5;
  else if(dDeg <= (60*10)) return 60*10;
  else if(dDeg <= (60*20)) return 60*20;
  else if(dDeg <= (60*30)) return 60*30;
  else return 60*45;
}

Graticule.prototype.gridPrecision = function(dDeg) {
	if(dDeg < 0.01) return 3;
	else if(dDeg < 0.1) return 2;
	else if(dDeg < 1) return 1;
  return 0;
}
  
Graticule.prototype.createLine = function(x,y,w,h) {
	var d = document.createElement("DIV");
  var s = d.style;
	s.position = "absolute";
	s.overflow = "hidden";
	s.backgroundColor = this.color_;
	s.left = x+"px";
	s.top = y+"px";
	s.width = w+"px";
	s.height = h+"px";
  s.opacity = 0.3;
  return d;
}
Graticule.prototype.createVLine = function(x) { return this.createLine(x,this.minY,"1",(this.maxY-this.minY)); }
Graticule.prototype.createHLine = function(y) { return this.createLine(0,y,this.map_.getSize().width,"1"); }

//returns a div that is a horizontal single pixel line, across the dateline  
//we find the start and width of a 180 degree line and draw the same amount to its left and right	  
Graticule.prototype.createHLine3 = function(lat) {
	var f = this.latLngToPixel(lat,0);
	var t = this.latLngToPixel(lat,180);		
	var div = document.createElement("DIV");
	div.style.position = "absolute";
	div.style.overflow = "hidden";
	div.style.backgroundColor = this.color_;
	var x1 = f.x;
	var x2 = t.x;
	if(x2 < x1){
		x2 = f.x;
		x1 = t.x;
	}
	div.style.left = (x1-(x2-x1)) + "px";
	div.style.top = f.y + "px";
	div.style.width = ((x2-x1)*3) + "px";
	div.style.height = "1px";
	return div;
}  


/* Dependencies: google.maps */

var CCHDO = CCHDO ? CCHDO : {};
CCHDO.Util = {};
CCHDO.Util.get_abs_mouse_position = function(e) {
  var posX = 0;
  var posY = 0;
  if (!e) { e = window.event; }
  if (e.pageX || e.pageY) {
    posX = e.pageX;
    posY = e.pageY;
  } else if (e.clientX || e.clientY){
    var dE = document.documentElement;
    posX = e.clientX + (dE.scrollLeft ? dE.scrollLeft : document.body.scrollLeft);
    posY = e.clientY + (dE.scrollTop ? dE.scrollTop : document.body.scrollTop);
  }	
  return new google.maps.Point(posX, posY);  
};
CCHDO.Util.get_dom_pos = function(element) {
  var leftPos = element.offsetLeft;        // initialize var to store calculations
  var topPos = element.offsetTop;          // initialize var to store calculations
  var parElement = element.offsetParent;   // identify first offset parent element  
  while (parElement !== null ) {           // move up through element hierarchy
    leftPos += parElement.offsetLeft;      // appending left offset of each parent
    topPos += parElement.offsetTop;  
    parElement = parElement.offsetParent;  // until no more offset parents exist
  }
  return new google.maps.Point(leftPos, topPos);
};
CCHDO.Util.apply_styles = function(domelem, styles) {
  for (var s in styles) { domelem.style[s] = styles[s]; }
};
CCHDO.Util.get_radius_coord = function(center, radius) {
  if (radius <= 0) { return center; }
  var EARTH_RADIUS = 6378.137; //km
  var arclen = radius / EARTH_RADIUS;
  var deltalng = Math.acos((Math.cos(arclen) - Math.pow(Math.sin(center.latRadians()), 2)) /
                           Math.pow(Math.cos(center.latRadians()), 2));
  return new google.maps.LatLng(center.lat(), (center.lngRadians() + deltalng) * 180 / Math.PI);
};
CCHDO.Util.get_circle_on_map_from_pts = function(map, center, outer, color) {
  var radius = Math.sqrt(Math.pow(center.x - outer.x, 2) + Math.pow(center.y - outer.y, 2));
  var NUMSIDES = 20;
  var SIDELENGTH = 18;
  var sideLengthRad = SIDELENGTH * Math.PI/180;
  var maxRad = (NUMSIDES+1) * sideLengthRad;
  var pts = [];
  for (var aRad=0; aRad < maxRad; aRad+=sideLengthRad) {
    var pixelX = center.x + radius*Math.cos(aRad);
    var pixelY = center.y + radius*Math.sin(aRad);
    pts.push(map.fromContainerPixelToLatLng(new google.maps.Point(pixelX, pixelY)));
  }
  
  return new google.maps.Polygon(pts, color, 2, 0.5, color, 0.5);
};
CCHDO.Util.get_circle_on_map_from_latlngs = function(map, centerlatlng, outerlatlng, color) {
  var center = map.fromLatLngToContainerPixel(centerlatlng);
  var outer = map.fromLatLngToContainerPixel(outerlatlng);
  return CCHDO.Util.get_circle_on_map_from_pts(map, center, outer, color);
};

function DragTool() {}

DragTool.prototype.initialize = function() {
  var G = this.globals;
  G.ear = document.createElement('div');
  G.ear.id = 'dragtool-ear';
  G.ear.onselectstart = function() {return false;}; /* disable text selection for IE on ear */
  CCHDO.Util.apply_styles(G.ear, {position: 'absolute', display: 'none',
                               overflow: 'hidden', cursor: 'crosshair',
                               zIndex: 200, opacity: G.style.opacity,
                               filter: "alpha(opacity="+G.style.opacity+")",
                               background: G.style.listenColor});
  var mapDiv = G.map.getContainer();
  G.mapPosition = CCHDO.Util.get_dom_pos(mapDiv);
  mapDiv.appendChild(G.ear);
  
  var me = this;
  var GMEaD = google.maps.Event.addDomListener;
  GMEaD(G.ear, 'mousedown', function(e) { me.mousedown_(e); });
  GMEaD(G.ear, 'mousemove', function(e) {
    if (G.dragging) { me.drag_(e);
    } else { me.mousemove_(e); }
  });
  GMEaD(G.ear, 'mouseup', function(e) { me.mouseup_(e); });
};

DragTool.prototype.mousedown_ = function(e){
  var G = this.globals;
  G.dragging = true;
  this.erase();

  /* update start position */
  G.coords[0] = G.coords[1] = this.get_mouse_rel_pos_(e);

  this.redraw();

  if (G.hooks.dragstart) { G.hooks.dragstart(this.get_bounds()); }
};

DragTool.prototype.mousemove_ = function(e) {
  var G = this.globals;
  if (G.hooks.moving) { G.hooks.moving(this.get_mouse_rel_pos_(e)); }
};

DragTool.prototype.drag_ = function(e){
  var G = this.globals;
  G.coords[1] = this.get_mouse_rel_pos_(e);
  this.redraw();

  if (G.hooks.dragging) { G.hooks.dragging(this.get_bounds()); }
};

DragTool.prototype.mouseup_ = function(e) {
  var G = this.globals;
  G.dragging = false;

  G.coords[1] = this.get_mouse_rel_pos_(e);
  this.redraw();

  this.close_ear();

  if (G.hooks.dragend) { G.hooks.dragend(this.get_bounds()); }
};

DragTool.prototype.erase = function() {
	var G = this.globals;
	if (G.marker) {
		G.map.removeOverlay(G.marker);
		G.marker = null;
	}
};

DragTool.prototype.redraw = function() {
  var G = this.globals;
  /* Save calculation before the erase (it clobbers G.marker) to prevent flashing. */
  var marker = this.get_polygon();
  this.erase();
  G.marker = marker;
  G.map.addOverlay(G.marker);
};

DragTool.prototype.map_width = function() { return this.globals.map.getSize().width; };
DragTool.prototype.map_height = function() { return this.globals.map.getSize().height; };

DragTool.prototype.sync_ear = function() {
  CCHDO.Util.apply_styles(this.globals.ear,
    {top: '0', left: '0', width: this.map_width()+'px', height: this.map_height()+'px'});
};

DragTool.prototype.open_ear = function(){
  var G = this.globals;
  G.mapPosition = CCHDO.Util.get_dom_pos(G.map.getContainer());
  this.sync_ear();
  CCHDO.Util.apply_styles(G.ear, {display: 'block'});
};

DragTool.prototype.close_ear = function() {
  CCHDO.Util.apply_styles(this.globals.ear, {display: 'none'});
};

DragTool.prototype.get_mouse_rel_pos_ = function(e) {
  var G = this.globals;
  var pos = CCHDO.Util.get_abs_mouse_position(e);
  var mapPos = G.mapPosition;
  return G.map.fromContainerPixelToLatLng(new google.maps.Point(pos.x - mapPos.x, pos.y - mapPos.y));
};

/* DragRectangle */
function DragRectangle(map, hooks) {
  var G = this.globals = {
    dragging: false,
    mapPosition: null,
    map: map,
    ear: null,
    marker: null,
    coords: [new google.maps.LatLng(0, 0), new google.maps.LatLng(0, 0)]
  };
  G.style = {
    opacity: 0.2,
    listenColor: '#888888',
    markerColor: '#ff0000',
    markerWidth: 2
  };
  G.hooks = hooks ? hooks : {};
  this.initialize();
}
DragRectangle.prototype = new DragTool();
DragRectangle.prototype.constructor = DragRectangle;

/* hooks:
 *   listening
 *   moving(google.maps.Point)
 *   dragstart(google.maps.LatLngBounds)
 *   dragging(google.maps.LatLngBounds)
 *   dragend(google.maps.LatLngBounds)
 *   ignoring */
DragRectangle.prototype.set_bounds = function(glatlngbounds) {
  var G = this.globals;
  G.coords[0] = glatlngbounds.getSouthWest();
  G.coords[1] = glatlngbounds.getNorthEast();
};

DragRectangle.prototype.get_bounds = function() {
  var G = this.globals;

  /* Normalize the 4 start and end point cases to the case where it is sw and ne. */
  var st = G.map.fromLatLngToContainerPixel(G.coords[0]);
  var en = G.map.fromLatLngToContainerPixel(G.coords[1]);
  var swpt = G.map.fromLatLngToContainerPixel(G.coords[0]);
  var nept = G.map.fromLatLngToContainerPixel(G.coords[1]);
  if (st.x > en.x) { /* went left */
	  if (st.y < en.y) { /* went down (picture coord-sys) */
	    swpt = en;
	    nept = st;
	  } else {
	    swpt = new google.maps.Point(en.x, st.y);
	    nept = new google.maps.Point(st.x, en.y);
	  }
  } else {
	  if (st.y < en.y) {
	    swpt = new google.maps.Point(st.x, en.y);
	    nept = new google.maps.Point(en.x, st.y);
	  } else { /* Already normal */ }
  }

  /* Get LatLng of start and end pts */
	var sw = G.map.fromContainerPixelToLatLng(swpt);
	var ne = G.map.fromContainerPixelToLatLng(nept);

  return new google.maps.LatLngBounds(sw, ne);
};

/* Provides a polygon with padding vertices at points in between the four
 * corners to prevent snapping the wrong way around the world. */
DragRectangle.prototype.get_polygon = function(bounds) {
  bounds = this.get_bounds();
  var G = this.globals;
  var GML = google.maps.LatLng
  var center = bounds.getCenter();
  var interlng = center.lng();
  var interlat = center.lat();
  
  var ne = bounds.getNorthEast();
  var sw = bounds.getSouthWest();
  var nw = new GML(ne.lat(), sw.lng());
  var se = new GML(sw.lat(), ne.lng());

  var n = new GML(nw.lat(), interlng);
  var s = new GML(sw.lat(), interlng);
  var e = new GML(interlat, se.lng());
  var w = new GML(interlat, sw.lng());
  return new google.maps.Polygon([nw, n, ne, e, se, s, sw, w, nw],
                                 G.style.markerColor, G.style.markerWidth, 0.6);
};

/* DragCircle */
function DragCircle(map, hooks) {
  var G = this.globals = {
    dragging: false,
    mapPosition: null,
    map: map,
    ear: null,
    marker: null,
    coords: [new google.maps.LatLng(0, 0), new google.maps.LatLng(0, 0)]
  };
  G.style = {
    opacity: 0.2,
    listenColor: '#888888',
    markerColor: '#0088ff',
    markerWidth: 2
  };
  G.hooks = hooks ? hooks : {};
  this.initialize();
}
DragCircle.prototype = new DragTool();
DragCircle.prototype.constructor = DragCircle;

/* hooks:
 *   listening
 *   moving(google.maps.Point)
 *   dragstart({google.maps.LatLng, Number})
 *   dragging({google.maps.LatLng, Number})
 *   dragend({google.maps.LatLng, Number})
 *   ignoring */
/* The circle defined by the two coords has the radius specified in the horizontal axis toward the east */
DragCircle.prototype.set_bounds = function(center, radius) {
  var G = this.globals;
  G.coords[0] = center;
  G.coords[1] = CCHDO.Util.get_radius_coord(center, radius);
};

DragCircle.prototype.get_bounds = function() {
  var G = this.globals;
  return {latlng: G.coords[0], radius: this.radius()};
};

DragCircle.prototype.radius = function() {
  var G = this.globals;
  var center = G.coords[0];
  var outer = G.coords[1];
  return center.distanceFrom(outer)/1000;
};

DragCircle.prototype.get_polygon = function() {
  var G = this.globals;
  return CCHDO.Util.get_circle_on_map_from_latlngs(G.map, G.coords[0], G.coords[1], G.style.markerColor);
};


// Dependecies:
// jQuery 1.4.0+
// kmldomwalk
// google.maps 2.x
var CCHDO = CCHDO ? CCHDO : {};
var CM = CCHDO.map_search = {
  map: null,
  ge: null,
  MIN_TIME: 1967,
  MAX_TIME: new Date().getFullYear()
};

/*=============================================================================
 * Controls */
var CMC = CM.ctrls = {};
CMC.deactivate_all_except = function(me) {
  CM.results.clear();
  for (var ctrl in CMC) {
    if (ctrl == 'time' || ctrl == 'deactivate_all_except' || CMC[ctrl] === me) { continue; }
    CMC[ctrl].setInactive();
  }
};
CMC.query = {
  setActive: function() {
    CMC.deactivate_all_except(this);
    $('#tool').val('query');
  },
  setInactive: function() {
    $('#tool').val('none');
  }
};
CMC.rectangle = {
  mark: function() {
    this.control.set_bounds(new google.maps.LatLngBounds(this.getSW(), this.getNE()));
    this.control.redraw();
  }, //sanitizing in controller
  setActive: function() {
    CMC.deactivate_all_except(this);
    $('#tool').val('rectangle');
    this.mark();
  },
  setInactive: function() {
    $('#tool').val('none');
    this.control.close_ear();
    this.control.erase();
  },
  sync: function() {
    this.setActive();
  },
  getSW: function() { return new google.maps.LatLng(parseFloat(this.sw_lat_box.val()), parseFloat(this.sw_lng_box.val())); },
  getNE: function() { return new google.maps.LatLng(parseFloat(this.ne_lat_box.val()), parseFloat(this.ne_lng_box.val())); },
  setSWBox: function(latlng) {
    this.sw_lat_box.val(latlng.lat());
    this.sw_lng_box.val(latlng.lng());
  },
  setNEBox: function(latlng) {
    this.ne_lat_box.val(latlng.lat());
    this.ne_lng_box.val(latlng.lng());
  },
  hook_moving: function(pt) {
    var latlng = CM.map.fromContainerPixelToLatLng(pt);
    CMC.rectangle.setSWBox(latlng);
    CMC.rectangle.setNEBox(latlng);
    this.setActive();
  },
  hook_dragging: function(bounds) {
    this.setSWBox(bounds.getSouthWest());
    this.setNEBox(bounds.getNorthEast());
  },
  hook_dragend: function(selection) {
    this.setSWBox(selection.getSouthWest());
    this.setNEBox(selection.getNorthEast());
    CM.recenter();
    CM.remote_submit();
  }
};
CMC.circle = {
  mark: function() {
    this.control.set_bounds(new google.maps.LatLng(parseFloat(this.center_lat_box.val()),
                                                   parseFloat(this.center_lng_box.val())),
                            parseFloat(this.radius_box.val()));
    this.control.redraw();
  },
  setActive: function() {
    CMC.deactivate_all_except(this);
    $('#tool').val('circle');
    this.mark();
  },
  setInactive: function() {
    $('#tool').val('none');
    this.control.close_ear();
    this.control.erase();
  },
  sync: function() {
    this.setActive();
  },
  setCircleCenterBox: function(bounds) {
    var latlng = bounds.latlng;
    this.center_lat_box.val(latlng.lat());
    this.center_lng_box.val(latlng.lng());
    this.radius_box.val(bounds.radius);
  },
  hook_moving: function(pt) {
    CMC.circle.setCircleCenterBox({latlng: CM.map.fromContainerPixelToLatLng(pt), radius: 0});
    this.setActive();
  },
  hook_dragging: function(bounds) {
    this.setCircleCenterBox(bounds);
  },
  hook_dragend: function(bounds) {
    CM.recenter();
    CM.remote_submit();
  }
};
CMC.polygon = {
  polygon: null,
  ear: null,
  delete_ear: null,
  drawing: false,
  ignorecnt: 0,
  drawNew: function() {
    var me = this;
    var listento = google.maps.Event.addListener;
    me.clear();
    $('#polygon_status').html('Ready - click on first vertex.');
    if(!me.ear) {
      me.ear = listento(CM.map, 'click', function(overlay, latlng) {
        google.maps.Event.removeListener(me.ear);
        me.ear = null;
        var color = "#aa22ff";
        $('#polygon_status').html('Drawing - click on next vertex or first vertex to end');
        me.polygon = new google.maps.Polygon([latlng], color, 3, 1.0, color, 0.5);
        //listento(me.polygon, 'mouseover', function(){me.edit();});
        //listento(me.polygon, 'mouseout', function(){me.stone();});
        CM.map.addOverlay(me.polygon);
        me.polygon.enableDrawing();
        me.drawing = true;
        listento(me.polygon, 'endline', function(){
          me.drawing = false;
          me.setActive();
          CM.remote_submit();
          $('#polygon_status').html('Inactive - click on <img src="/images/map_search/select_polygon_button_off.gif" /> to start');
        });
      });
    }
  },
  stopDraw: function() {
    if(this.polygon){
      CM.map.removeOverlay(this.polygon);
      this.polygon = null;
    }
    $('#polygon_status').html('Inactive - click on <img src="/images/map_search/select_polygon_button_off.gif" /> to start');
  },
  clear: function() {
    if(this.polygon) {
      this.stone();
      CM.map.removeOverlay(this.polygon);
    }
  },
  edit: function() {
    var me = this;
    me.polygon.enableEditing();
    if(!me.delete_ear) {
      me.delete_ear = google.maps.Event.addListener(CM.map, "singlerightclick", function(pt, src, olay){
        if(typeof(olay.index) !== "undefined"){
          me.polygon.deleteVertex(olay.index);
        }
      });
    }
  },
  stone: function() {
    this.polygon.disableEditing();
    if(this.delete_ear){
      google.maps.Event.removeListener(this.delete_ear);
      this.delete_ear = null;
    }
  },
  mark: function() {
    if(this.polygon) {
      CM.map.addOverlay(this.polygon);
    }
  },
  setActive: function() {
    CMC.deactivate_all_except(this);
    $('#tool').val('polygon');
    this.mark();
    $('#polygon_status').html('Inactive - click on <img src="/images/map_search/select_polygon_button_off.gif" /> to start');
    $('#polygon_status').css('color', '#aa22ff');
  },
  setInactive: function() {
    $('#tool').val('none');
    this.clear();
  },
  sync: function() {
    this.mark();
  },
  toLineString: function() {
    var coords = [];
    for(var i=0; i<this.polygon.getVertexCount(); i++ ) {
      var v = this.polygon.getVertex(i);
      coords.push(v.lng()+' '+v.lat());
    }
    return "LINESTRING("+coords.join(', ')+")";
  }
};
CMC.importpt = {
  importedCircles: [],
  setActive: function() {
    var ctrls = CMC;
    ctrls.query.setInactive();
    ctrls.rectangle.setInactive();
    ctrls.circle.setInactive();
    ctrls.polygon.setInactive();
    this.clear();
    CM.results.clear();
    $('#tool').val('import');
    var latlngs = $('#latlons').val().split("\n").map(function(x) {
      var latlng = x.split(', ').map(function(x) {return parseInt(x, 10);});
      return new google.maps.LatLng(latlng[0], latlng[1]);
    });
    if (latlngs.length > 0) {
      this.mark(latlngs, parseInt($('#import_radius').val(), 10));
    }
  },
  setInactive: function() {
    $('#tool').val('none');
    this.clear();
  },
  clear: function() {
    while (this.importedCircles.length > 0) {
      CM.map.removeOverlay(this.importedCircles.pop());
    }
  },
  mark: function(latlngs, radius) {
    for (var i=0; i < latlngs.length; i++) {
      var marker = new google.maps.Marker(latlngs[i], CM.entries.station_marker);
      CM.map.addOverlay(marker);
      this.importedCircles.push(marker);
      var circle = CM.get_circle(latlngs[i], radius, '#88ff88');
      CM.map.addOverlay(circle);
      this.importedCircles.push(circle);
    }
  }
};
CMC.importFile = {
  setActive: function() {
    CMC.deactivate_all_except(this);
    $('#tool').val('importFile');
  },
  sync: function() {this.setActive();},
  setInactive: function() {},
  gotoImported: function(jobj) {
    if (jobj.data('kml')) {
      var kml = jobj.data('kml');
      CM.map.getEarthInstance(function(ge) {
        if (!ge) {return;}
        ge.getFeatures().appendChild(kml);
        if (kml.getAbstractView) {
          ge.getView().setAbstractView(kml.getAbstractView());
        }
      });
    } else {
      var polyline = jobj.data('nav');
      CM.map.addOverlay(polyline);
      CM.map.setCenter(polyline.getBounds().getCenter());
    }
  },
  removeImported: function(jobj) {
    if (jobj.data('kml')) {
      var kml = jobj.data('kml');
      CM.map.getEarthInstance(function(ge) {
        if (!ge) {return;}
        ge.getFeatures().removeChild(kml);
      });
    } else {
      var polyline = jobj.data('nav');
      CM.map.removeOverlay(polyline);
    }
  },
  newImportedFile: function(file) {
    return $('<div>'+file+'</div>')
      .appendTo('#imported_files')
      .prepend($('<input type="checkbox" checked="true" />').click(function() {
        if ($(this).is(':checked')) {
          CMC.importFile.gotoImported($(this).parent());
        } else {
          CMC.importFile.removeImported($(this).parent());
        }
      }))
      .append($('<span style="width: 2em;">&nbsp;</span><a href="#">Delete</a><span style="width: 2em;">&nbsp;</span>').click(function() {
        CMC.importFile.removeImported($(this).parent());
        $(this).parent().removeData('kml').removeData('nav').remove();
      }));
  },
  getKmlTour: function(kmlobj) {
    var tour = null;
    walkKmlDom(kmlobj, function() {
      if (this.getType() == 'KmlTour') {
        tour = this;
        return false;
      }
    });
    return tour;
  },
  importKMLFile: function(file, filename) {
    CM.map.getEarthInstance(function(ge) {
      google.earth.fetchKml(ge, 'http://'+window.location.host+'/'+file, function(kmlobj) {
        if (kmlobj) {
          var importedFile = CMC.importFile.newImportedFile(filename).data('kml', kmlobj);
          var tour = CMC.importFile.getKmlTour(kmlobj);
          if (tour) {
            importedFile.append($(' <a href="#">Play</a>').click(function() {
              CM.map.getEarthInstance(function(ge) {
                if (!ge) {return;}
                ge.getTourPlayer().setTour(tour);
                ge.getTourPlayer().play();
              });
            }));
          }
          CMC.importFile.gotoImported(importedFile);
        } else {
          alert('Sorry, there was an error loading the file.');
        }
      });
    });
    CM.map.setMapType(G_SATELLITE_3D_MAP);
  },
  importNAVFile: function(file, filename) {
    $.ajax({type: 'GET', dataType: 'text', url: 'http://'+window.location.host+'/'+file,
      success: function(nav) {
        var coords = $.map(nav.split('\n'), function(coordstr) {
          var coord = coordstr.replace(/^\s+/, '').split(/\s+/);
          if (isNaN(coord[0]) || isNaN(coord[1])) { return null; }
          return new G.LatLng(parseFloat(coord[1]), parseFloat(coord[0]));
        });
        var color = $('#navcolor').val();
        if (!color) { color = '#f00'; }
        var polyline = new G.Polyline(coords, color);
        CMC.importFile.gotoImported(CMC.importFile.newImportedFile(filename).data('nav', polyline));
      }
    });
  }
};
CMC.time = {
  min_time: null,
  max_time: null,
  sanitize: function() {
    var T = CMC.time;
    var max_time = parseInt(T.max_time.value, 10);
    var min_time = parseInt(T.min_time.value, 10);
    if (max_time < min_time) {
      var tmp = T.min_time.value;
      T.min_time.value = T.max_time.value;
      T.max_time.value = tmp;
      CM.state('Swapped min time with max time; the values you entered were not min/max.');
    }
    if (min_time < CM.MIN_TIME) { T.min_time.value = CM.MIN_TIME; }
    if (max_time > CM.MAX_TIME) { T.max_time.value = CM.MAX_TIME; }
  }
};
/*=============================================================================
 * Pane */
CM.Pane = function() {
  window.onresize = function() { CM.pane.refresh_map(); };
};
CM.Pane.prototype = {
  active: false,
  shaded: false,
  map_ratio: 0.55,
  handle_width: 15,
  width: $('#map_space').attr('offsetWidth')
};
CM.Pane.prototype.redraw = function() {
  this.width = $('#map_space').attr('offsetWidth');
  if (this.active) {
    $('#pane_handle').css('width', this.handle_width+'px');
    $('#handle_img').css('width', this.handle_width+'px');
    $('#map_pane').show();
    $('#pane_content').css('marginLeft', this.handle_width+'px');
    if (this.shaded) {
      var map_width = this.width - this.handle_width;
      $('#map').css('width', map_width+'px');
      $('#map_pane').css({'left': map_width+'px', 'width': this.handle_width+'px'});
      $('#handle_img').attr('src', '/images/map_search/shade_arrow_left.png');
      $('#pane_content').hide();
   } else {
      var map_width = this.width * this.map_ratio;
      $('#map').css('width', map_width+'px');
      $('#map_pane').css({'left': map_width+'px', 'width': (this.width - map_width)+'px'});
      $('#handle_img').attr('src', '/images/map_search/shade_arrow_right.png');
      $('#pane_content').show();
    }
  } else {
    $('#map').css('width', this.width+'px');
    $('#map_pane').hide();
  }
};
CM.Pane.prototype.refresh_map = function() {
  this.redraw();
  CM.map.checkResize();
  CM.recenter();
};
CM.Pane.prototype.activate = function() {
  /* Show the pane handle and content */
  this.active = true;
  this.refresh_map();
};
CM.Pane.prototype.deactivate = function() {
  /* Hide the pane handle and content */
  this.active = false;
  this.refresh_map();
};
CM.Pane.prototype.shade = function() {
  /* Hide the pane contents */
  this.shaded = true;
  this.refresh_map();
};
CM.Pane.prototype.unshade = function() {
  /* Show the pane contents */
  this.shaded = false;
  this.refresh_map();
};
CM.Pane.prototype.toggle = function() {
  if (this.shaded) { this.unshade(); } else { this.shade(); }
};
CM.pane = new CM.Pane();
$('#pane_handle').click(function() { CM.pane.toggle(); });

/*=============================================================================
 * Entries */
CM.entries = {
  entries: [],
  drilled: -1,
  station_marker: {icon: new google.maps.Icon(), clickable: false},
  cruise_start_marker: {icon: new google.maps.Icon()},
  initial_color: '#00aa00',
  light_poly_style: {color: "#ff8800"},
  dim_poly_style: {color: "#ffcc00"},
  dark_poly_style: {color: "#00aa00"}
};
CM.entries.init = function() {
  var G = google.maps;
  var c = CM.entries.cruise_start_marker.icon;
  c.image = 'http://'+window.location.host+"/images/map_search/cruise_start_icon.png";
  c.iconSize = new G.Size(24, 12);
  c.shadowSize = new G.Size(0, 0);
  c.iconAnchor = new G.Point(12, 12);
  c.infoWindowAnchor = new G.Point(0, 0);
  var s = CM.entries.station_marker.icon;
  s.image = 'http://'+window.location.host+"/images/map_search/station_icon.png";
  s.iconSize = new G.Size(32, 32);
  s.shadowSize = new G.Size(0, 0);
  s.iconAnchor = new G.Point(0, 32);
  s.infoWindowAnchor = new G.Point(0, 0);
  s.imageMap = [0,0, 3,0, 3,3, 0,3];
}(); /* note the init is called! */
CM.entries.add = function(track) {
  var G = google.maps;
  var entry = {
    start_station: new G.Marker(track[0], this.cruise_start_marker),
    track: new G.Polyline(track, this.initial_color, 2, 1),
    stations: []
  };
  CM.map.addOverlay(entry.start_station);
  CM.map.addOverlay(entry.track);
  var id = this.entries.length;
  this.entries[id] = entry;
  return id;
};
CM.entries.remove = function(id) {
  var entry = this.get(id);
  if (entry === undefined) { return; }
  CM.state('Removing '+entry.expocode);
  var G = google.maps;
  var map = CM.map;
  map.removeOverlay(entry.start_station);
  map.removeOverlay(entry.track);
  while (entry.stations.length > 0) {
    CM.map.removeOverlay(entry.stations.pop());
  }
  CM.state('');
};
CM.entries.get = function(id) { return this.entries[id]; };
CM.entries.lighten = function(id) {
  var entry = this.get(id);
  if (entry === undefined) { return; }
  entry.track.setStrokeStyle(this.light_poly_style);
  entry.track.redraw(true);
  var self = this;
  setTimeout(function() {
    for (var i=1; i<entry.track.getVertexCount(); i++) {
      var station = new google.maps.Marker(entry.track.getVertex(i), self.station_marker);
      entry.stations.push(station);
      CM.map.addOverlay(station);
    }
  }, 0);
};
CM.entries.dim = function(id) {
  var entry = this.get(id);
  if (entry === undefined) { return; }
  entry.track.setStrokeStyle(this.dim_poly_style);
  entry.track.redraw(true);
};
CM.entries.darken = function(id) {
  var entry = this.get(id);
  if (entry === undefined) { return; }
  while (entry.stations.length > 0) {
    CM.map.removeOverlay(entry.stations.pop());
  }
  entry.stations = [];
  entry.track.setStrokeStyle(this.dark_poly_style);
  entry.track.redraw(true);
};

/*=============================================================================
 * Info */
CM.Info = function() {
  $('#pop_button').click(function() { CM.info.popout(); });
  (function popup_close_guard() {
    if (CM.info_table_popped && CM.info_table_popped.closed) { CM.info.popin(); }
    setTimeout(popup_close_guard, 1000);
  })();
  this.setJdom($('#info_table'));
};
CM.Info.prototype = {
  jdom: null,
  info_table: null,
  info_data_table: new google.visualization.DataTable({
    cols: [{label: 'Line', type: 'string'},
           {label: 'ExpoCode', type: 'string'},
           {label: 'Ship', type: 'string'},
           {label: 'Country', type: 'string'},
           {label: 'PI', type: 'string'},
           {label: 'Begin Date', type: 'date'}],
    rows: []
  }, 0.6), /* = wire protocol version */
  data_table_opts: {
    allowHtml: true,
    alternatingRowStyle: true,
    height: 590,
    sort: 'enable',
    sortColumn: 5,
    sortAscending: false
  },
  i_to_d: null
};
CM.Info.prototype.table_rows = function() { return $('tr', this.jdom); }
CM.Info.prototype.setJdom = function(jdom) {
  if (this.jdom) {
    this.jdom.empty();
    delete this.info_table;
  }
  this.jdom = jdom;
  this.info_table = new google.visualization.Table(this.jdom[0]);

  var CMI = this;
  this.table_rows()
    .live('mouseenter', function() {
      CM.results.dim(CMI.get_id(this), true);
      return false;
    })
    .live('mouseleave', function() {
      CM.results.darken(CMI.get_id(this), true);
      return false;
    })
    .live('click', function() {
      CM.results.lighten(CMI.get_id(this), true);
      return false;
    });
  google.visualization.events.addListener(this.info_table, 'sort', function(event) {
    CMI.sync_sortorder(event);
  });
};
CM.Info.prototype.sync_sortorder = function(sortorder) {
  if (!sortorder) {return;}
  this.data_table_opts.sortColumn = sortorder.column;
  this.data_table_opts.sortAscending = sortorder.ascending;
  this.i_to_d = sortorder.sortedIndexes;
};
CM.Info.prototype.row_to_id = function(row) {
  if (this.i_to_d) { return this.i_to_d[row]; }
  return row;
};
CM.Info.prototype.id_to_row = function(id) {
  if (this.i_to_d) { return this.i_to_d.indexOf(id); }
  return id;
};
CM.Info.prototype.get_id = function(tr) {
  return this.row_to_id(this.get_row_num(tr));
};
CM.Info.prototype.get_row = function(id) {
  return this.table_rows()[this.id_to_row(id)+1];
};
CM.Info.prototype.get_row_num = function(tr) {
  for (var i=1; i<this.table_rows().length; i++) {
    var itr = this.table_rows()[i];
    if (tr === itr) { return i-1; }
  }
  return -1;
};
CM.Info.prototype.add = function(info, notrack) {
  var data_row = this.info_data_table.addRow([info.line, info.expocode, info.ship, info.country, info.pi, info.date_begin]);
  if (notrack) {
    for (var i=0; i<this.info_data_table.getNumberOfColumns(); i++) {
      this.info_data_table.setProperty(data_row, i, 'style', 'background-color: #ffdddd;');
    }
  }
  return data_row;
};
CM.Info.prototype.remove = function(id) { this.info_data_table.removeRow(id); this.redraw(); };
CM.Info.prototype.lighten = function(id) {
  this.info_table.setSelection([{row: id}]);
  this.selected = this.info_table.getSelection();
};
CM.Info.prototype.dim = function(id) {
  var row = this.get_row(id);
  var selection = this.info_table.getSelection();
  if (selection.length <= 0 || selection[0].row != id) {
    $(row).addClass('google-visualization-table-tr-over');
  }
};
CM.Info.prototype.darken = function(id) {
  var row = this.get_row(id);
  $(row).removeClass('google-visualization-table-tr-over');
  var selection = this.info_table.getSelection();
  if (selection.length > 0) {
    for (var i in selection) {
      if (selection[i].row == id) {
        selection.splice(i, 1);
        this.info_table.setSelection(selection);
      }
    }
  }
};
CM.Info.prototype.redraw = function() {
  if (this.info_table) {
    this.info_table.draw(this.info_data_table, this.data_table_opts);
    this.sync_sortorder(this.info_table.getSortInfo());
    if (this.selected) { this.info_table.setSelection(this.selected); }
  }
};
CM.Info.prototype.popout = function() {
  if (CM.info_table_popped) { return; }
  CM.pane.deactivate();
  CM.info_table_popped = window.open('', 'info_table_popped', 'toolbar=0,location=0');
  var doc = CM.info_table_popped.document;
  doc.write('<div id="centering"><div id="info_table"></div></div>');doc.close(); /* Strange hack that lets the window be written to later. */
  doc.title = 'CCHDO Map Search Results';
  $('head', doc)
    .append($('<base href="http://'+window.location.host+'" />', doc))
    .append($('<link rel="icon" type="image/x-icon" href="favicon.ico" />', doc));
  $('link').each(function() {
    if (this.rel == 'stylesheet') {
      $('<link href="'+this.href+'" rel="stylesheet" type="text/css" media="screen" />', doc).appendTo($('head', doc));
    }
  });
  var self = this;
  var close_button = $('<div id="pop_button">Close window <img src="images/map_search/popin.png" title="Popin" alt="Popin" /></div>')
    .click(function() { self.popin(); })
    .prependTo($('#centering', doc));
  if (CM.info_table_popped) {
    this.setJdom($('#info_table', doc));
    this.redraw();
  }
};
CM.Info.prototype.popin = function() {
  CM.info_table_popped.close();
  delete CM.info_table_popped;
  this.setJdom($('#info_table'));
  CM.pane.activate();
  CM.pane.unshade();
  this.redraw();
};
CM.info = new CM.Info();

/*=============================================================================
 * Entry Info results */
CM.results = {
  lit: -1,
  info_entry: {},
  entry_info: {},
  add: function(expocode, track) {
    /* Fetch more information for the cruise record display */
    track = track.map(function(x) {return new google.maps.LatLng(x[0], x[1]);});
    $.ajax({type: 'GET', url: '/map_search/info?expocode='+expocode, dataType: 'json',
      beforeSend: function() {CM.state('Fetching '+expocode);},
      success: function(response) {
        try {
          CM.state('Received '+expocode);
          var CME = CM.entries;
          var info = response;
          if (info) {
            info.expocode = '<a href="http://cchdo.ucsd.edu/data_access?ExpoCode='+expocode+'">'+expocode+'</a>';
            var date_begin = new Date();
            date_begin.setTime(Date.parse(info.date_begin));
            info.date_begin = date_begin;
            var date_end = new Date();
            date_end.setTime(Date.parse(info.date_end));
            info.date_end = date_end;
          } else {
            info = {'expocode': '<a href="http://cchdo.ucsd.edu/data_access?ExpoCode='+expocode+'">'+expocode+'</a>',
                    'line': null, 'ship': null, 'country': null, 'pi': null, 'date_begin': null};
          }
          /* Plot the cruise track and do the appropriate event attaching */
          var G = google.maps;
          var entry_id;
          var info_id;
          if (track.length > 0) {
            CM.state('Plotting '+expocode);
            entry_id = CM.entries.add(track);
          }

          CM.state('Linking '+expocode);
          var CMR = CM.results;
          var CMI = CM.info;
          var entry = CM.entries.get(entry_id);
          if (entry) {
            G.Event.addListener(entry.track, 'mouseout', function() { CMR.darken(entry_id); });
            G.Event.addListener(entry.track, 'mouseover', function() { CMR.dim(entry_id); });
            G.Event.addListener(entry.track, 'click', function() { CMR.lighten(entry_id); });
            G.Event.addListener(entry.start_station, 'mouseout', function() { CMR.darken(entry_id); });
            G.Event.addListener(entry.start_station, 'mouseover', function() { CMR.dim(entry_id); });
            G.Event.addListener(entry.start_station, 'click', function() { CMR.lighten(entry_id); });
            info_id = CMI.add(info);
          } else {
            info_id = CMI.add(info, true);
          }

          CMR.info_entry[info_id] = entry_id;
          CMR.entry_info[entry_id] = info_id;

          CMI.redraw();

          CM.state('');
        } catch(e) {
          console.log('Error handling received cruise information:', e);
        }
      }
    });
  },
  clear: function() {
    for (var info_id in this.info_entry) {
      this.remove(parseInt(info_id, 10), true);
    }
  },
  remove: function(id, is_info_id) {
    if (!is_info_id) { id = this.entry_info[id]; }
    var entry_id = this.info_entry[id];
    CM.entries.remove(entry_id);
    CM.info.remove(id);
    if (id == this.lit) { this.lit = -1; }
    for (var entry_id in this.entry_info) {
      if (this.entry_info[entry_id] > id) { this.entry_info[entry_id]--; }
    }
    var max = -1;
    for (var info_id in this.info_entry) {
      if (info_id > id) { this.info_entry[info_id-1] = this.info_entry[info_id]; }
      max = Math.max(max, info_id);
    }
    delete this.entry_info[entry_id];
    delete this.info_entry[max];
  },
  lighten: function(id, is_info_id) {
    if (!is_info_id) { id = this.entry_info[id]; }
    if (id > -1) {
      if (this.lit > -1 && this.lit != id) {
        CM.entries.darken(this.info_entry[this.lit]);
        CM.info.darken(this.lit);
      }
      CM.entries.lighten(this.info_entry[id]);
      CM.info.lighten(id);
      this.lit = id;
    }
  },
  dim: function(id, is_info_id) {
    if (!is_info_id) { id = this.entry_info[id]; }
    if (id > -1 && this.lit != id) {
      CM.entries.dim(this.info_entry[id]);
      CM.info.dim(id);
    }
  },
  darken: function(id, is_info_id) {
    if (!is_info_id) { id = this.entry_info[id]; }
    if (id > -1 && this.lit != id) {
      CM.entries.darken(this.info_entry[id]);
      CM.info.darken(id);
    }
  }
};

/*=============================================================================
 * Tool bar */
CM.tool_bar = {
  active: null,
  need_granularity: ['query', 'rectangle', 'circle', 'polygon', 'import'],
  tool_button_to_tool_details: {}
};
CM.tool_bar.set_active = function(tool_button) {
  if (this.active) {
    $(CM.tool_bar.active).removeClass('active');
    this.tool_button_to_tool_details[this.active.id].style.display = 'none';
    if (this.need_granularity.indexOf(this.active.id.replace('_button', '')) != -1) {
      $('#granularity').hide();
    }
    $('#tool').val('none');
  }
  $(tool_button).addClass('active');
  this.active = tool_button;
  var details = this.tool_button_to_tool_details[tool_button.id];
  $(details).show();
  if (this.need_granularity.indexOf(tool_button.id.replace('_button', '')) != -1) {
    $('#granularity').show();
  }
  var tool = $('#tool').val(this.active.id.replace('_button', ''));
  if (tool == 'query') {
    CMC.query.setActive();
  } else if (tool == 'rectangle') {
    CMC.rectangle.setActive();
  } else if (tool == 'circle') {
    CMC.circle.setActive();
  } else if (tool == 'polygon') {
    CMC.polygon.setActive();
  } else if (tool == 'import') {
    CMC.importpt.setActive();
  }
};
CM.tool_bar.init = function() {
  var tool_bar = $('#tool_bar')[0];
  var tool_buttons = $(tool_bar).children();
  var self = this;
  for (var i=0; i < tool_buttons.size(); i++) {
    var tool_button = tool_buttons[i];
    /* Skip non-buttons, e.g. state */
    if (tool_button.className.indexOf('tool_button') == -1) { continue; }
    this.tool_button_to_tool_details[tool_button.id] = $('#'+tool_button.id.replace('_button', '')+'_details')[0];
    tool_button.onclick = function(e) {
      if (this === self.active) {
        var tool = $('#tool').val();
        if (tool == 'rectangle') {
          CMC.rectangle.control.erase();
          CMC.rectangle.control.open_ear();
        } else if (tool == 'circle') {
          CMC.circle.control.erase();
          CMC.circle.control.open_ear();
        } else if (tool == 'polygon') {
          CMC.polygon.drawNew();
        }
      } else {
        self.set_active(this);
      }
    };
  }
  this.set_active(tool_buttons[1]);
};
CM.init_ge = function(instance) {
};
CM.recenter = function() {
  if ($('#tool').val() == 'rectangle') {
    this.map.setCenter(this.ctrls.rectangle.control.get_bounds().getCenter());
  } else if ($('#tool').val() == 'circle') {
    this.map.setCenter(this.ctrls.circle.control.get_bounds().latlng);
  }
};
CM.tracks_handler = function(request) {
  var cruise_tracks = request;
  var check = undefined;
  for (var expocode in cruise_tracks) {
    check = expocode;
    CM.results.add(expocode, cruise_tracks[expocode]);
  }
  if (check === undefined) {
    CM.state('No cruises found');
    this.results.clear();
  } else {
    CM.pane.activate();
    CM.pane.unshade();
  }
};
CM.remote_submit = function() { $('#tool_details_form').submit(); };
CM.submit = function() {
  var type = $('#tool').val();
  if (type == 'query') {
    this.ctrls.query.setActive();
    this.results.clear();
    this.map.setCenter(new google.maps.LatLng(0, 0), 1);
  } else if (type == 'rectangle') {
    this.ctrls.rectangle.sync();
  } else if (type == 'circle') {
    this.ctrls.circle.sync();
  } else if (type == 'polygon') {
    $('#polygon').val(this.ctrls.polygon.toLineString());
    this.ctrls.polygon.sync();
  } else if (type == 'import') {
    this.ctrls.importpt.setActive();
  }
};
CM.get_circle = function(center, radius, polyColor) {
  if (radius <= 0) { return null; }
  var outer = this.map.fromLatLngToContainerPixel(CCHDO.Util.get_radius_coord(center, radius));
  center = this.map.fromLatLngToContainerPixel(center);
  return CCHDO.Util.get_circle_on_map_from_pts(this.map, center, outer, polyColor);
};
CM.initDragTool = function(ctrl, tool) {
  var hooks = {
    moving: function(point) { ctrl.hook_moving(point); },
    dragging: function(bounds) { ctrl.hook_dragging(bounds); },
    dragend: function(bounds) { ctrl.hook_dragend(bounds); }
  };
  return new tool(this.map, hooks);
};
CM.state = function(stat) { $('#status').html(stat); };
CM.load = function() {
  var G = google.maps;
  window.onunload=G.Unload;
  if (G.BrowserIsCompatible()) {
    var ctrls = CMC;
    var self = CM;
    var m = CM.map = new G.Map2($('#map')[0], {mapTypes: [G_PHYSICAL_MAP, G_SATELLITE_MAP, G_SATELLITE_3D_MAP]});
    m.setCenter(new G.LatLng(0, 0), 3);// MUST be done right after map creation
    ctrls.rectangle.control = CM.initDragTool(ctrls.rectangle, DragRectangle);
    ctrls.circle.control = CM.initDragTool(ctrls.circle, DragCircle);
    m.addControl(new G.SmallZoomControl());
    m.addControl(new G.MenuMapTypeControl());
    m.enableContinuousZoom();
    m.enableScrollWheelZoom();
    m.setMapType(G_PHYSICAL_MAP);
    G.Event.addListener(m, 'maptypechanged', function() {
      CM.map.getEarthInstance(function(ge) {
        if (!ge) {return;}
        ge.getOptions().setGridVisibility($('#gridon').is(':checked'));
        ge.getOptions().setAtmosphereVisibility($('#atmosphereon').is(':checked'));
      });
    });
  }

  var rctrl = ctrls.rectangle;
  rctrl.ne_lat_box = $('#ne_lat');
  rctrl.ne_lng_box = $('#ne_lng');
  rctrl.sw_lat_box = $('#sw_lat');
  rctrl.sw_lng_box = $('#sw_lng');
  var cctrl = ctrls.circle;
  cctrl.center_lat_box = $('#circle_center_lat');
  cctrl.center_lng_box = $('#circle_center_lng');
  cctrl.radius_box = $('#circle_radius');
  var tctrl = ctrls.time;
  tctrl.min_time = $('#min_time_display');
  tctrl.max_time = $('#max_time_display');

  $('.rectangle.coords').keyup(function() {rctrl.sync();});
  $('.circle.coords').keyup(function() {cctrl.sync();});
  $('.time.coords').blur(function() {tctrl.sanitize();});
  $('#query_details').click(function() {ctrls.query.setActive();});
  $('#rectangle_details').click(function() {ctrls.rectangle.setActive();});
  $('#circle_details').click(function() {ctrls.circle.setActive();});
  $('#polygon_details').click(function() {ctrls.polygon.setActive();});
  $('#import_details').click(function() {ctrls.importpt.setActive();});

  CM.tool_bar.init();
  CM.pane.deactivate();

  function setTimeDisplay(values) {
    tctrl.min_time.val(values[0]);
    tctrl.max_time.val(values[1]);
  }
  $('#timeslider').slider({
    range: true, min: CM.MIN_TIME, max: CM.MAX_TIME,
    values: [CM.MIN_TIME, CM.MAX_TIME],
    slide: function(event, ui) {
      setTimeDisplay(ui.values);
    }
  });
  setTimeDisplay($('#timeslider').slider('values'));

  /* No need to keep redrawing graticules while the page is resizing while loading */
  CM.graticule = new Graticule();
  CM.map.addOverlay(CM.graticule);

  $('#gridon').click(function() {
    var checked = $(this).is(':checked');
    CM.map.getEarthInstance(function(ge) {
      if (!ge) {return;}
      ge.getOptions().setGridVisibility(checked);
    });
    if (checked) {
      CM.map.addOverlay(CM.graticule);
    } else {
      CM.map.removeOverlay(CM.graticule);
    }
  });

  $('#atmosphereon').click(function() {
    var checked = $(this).is(':checked');
    CM.map.getEarthInstance(function(ge) {
      if (!ge) {return;}
      ge.getOptions().setAtmosphereVisibility(checked);
    });
  });

  $('#kmlupload').submit(function() {
    var filename = $('#kmlupload input[name=kml]').val();
    if (filename == '') { alert('Please specify a file'); return false; }
    $(this).ajaxSubmit({dataType: 'text',
      success: function(file) {
        var filetype = $('#kmlupload input[name=filetype]:checked').val();
        if (filetype == 'KML' && filename.slice(-4) != '.kml' && filename.slice(-4) != '.kmz') {
          if (!confirm('You said you were uploading a KML file. Continue with unexpected extension that is not .kml or .kmz?')) {
            return false;
          }
        }
        if (filetype != 'KML' && filename.slice(-6) != 'na.txt') {
          if (!confirm('You said you are uploading a NAV file. Continue with unexpected extension that is not na.txt?')) {
            return false;
          }
        }
        if (filetype == 'KML') {
          CMC.importFile.importKMLFile(file, filename);
        } else {
          CMC.importFile.importNAVFile(file, filename);
        }
      }
    });
    return false;
  });

  $('#tool_details_form').submit(function() {
    CM.submit();
    $.ajax({type: 'GET', url: '/map_search/tracks', data: $(this).serialize(), dataType: 'json',
      beforeSend: function() {CM.state('Searching <img src=\"/images/rotate.gif\" />');},
      success: function(response) {
        CM.state('');
        CM.tracks_handler(response);
      }
    });
    return false;
  });
  $('#tool_details_form_submit').click(function() {
    CM.remote_submit();
    return false;
  });

  ctrls.rectangle.sync();
};
CM.load_with_submit = function() {
  CM.load();
  CM.remote_submit();
};
CM.load_with_cruises = function(cruises) {
  CM.load();
  $.ajax({type: 'GET', url: '/map_search/tracks', data: 'tool=expocodes&expocodes='+cruises, dataType: 'json',
    beforeSend: function() {CM.state('Loading cruises <img src=\"/images/rotate.gif\" />');},
    success: function(response) {
      CM.state('');
      CM.tracks_handler(response);
    }
  });
}
google.setOnLoadCallback(CM.load);
