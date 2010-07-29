/* DragSelectCircleControl Class
Adapted from DragZoomControl under fair use as a Derivative Work: Licensed under the Apache License, Version 2.0 (the "License") you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.*/
var EARTH_RADIUS = 6371.01; //km

function DragSelectCircleControl(opts_boxStyle, opts_other, opts_hooks) {
  // Holds all information needed globally; Not all globals are initialized here
  this.globals = {
    draggingOn: false,
    mapPosition: null,
    mapWidth: 0,
    mapHeight: 0,
    mapRatio: 0,
    center: null,
    radius: 0
  };

  //box style options
  this.globals.style = {
    opacity: .2,
    fillColor: "#000",
    border: "2px solid #0ff"
  };

  var style = this.globals.style;
  for (var s in opts_boxStyle) {
    style[s]=opts_boxStyle[s];
  }

  var borderStyleArray = style.border.split(' ');
  style.outlineWidth = parseInt(borderStyleArray[0].replace(/\D/g,''));
  style.outlineColor = borderStyleArray[2];
  style.alphaIE = 'alpha(opacity=' + (style.opacity * 100) + ')';
 
  // map context stack for back button
  this.globals.backStack = [];

  // Other options
  this.globals.options={
    buttonHTML: 'select ...',
    buttonStartingStyle: 
      {width: '52px', border: '1px solid black', padding: '2px'},
    buttonStyle: {background: '#FFF'},
    buttonSelectingHTML: 'Drag a region on the map',
    buttonSelectingStyle: {background: '#FF0'},
    overlayRemoveTime: 6000,
  };
	
  for (var s in opts_other) {
    this.globals.options[s] = opts_other[s]
  }

  // hooks: buttonclick, dragstart, dragging, dragend, backbuttonclick 
  if (opts_hooks == null) {
    opts_hooks = {}
  }
  this.globals.hooks = opts_hooks;
}

DragSelectCircleControl.prototype = new GControl();

/* Methods */

/**
 * Initiate a dragSelect as if the user had.
 */
DragSelectCircleControl.prototype.initiateSelect = function() {this.buttonclick_()};

/**
 * Creates a new button to control gselect-circle and appends to the button container div.
 * @param {DOM Node} buttonContainerDiv created in main .initialize code
 */
DragSelectCircleControl.prototype.initButton_ = function(buttonContainerDiv) {
  var G = this.globals;
  var buttonDiv = document.createElement('div');
  buttonDiv.innerHTML = G.options.buttonHTML;
  buttonDiv.id = 'gselect-circle-control';
  DragSelectCircleUtil.style([buttonDiv], {cursor: 'pointer', zIndex:200});
  DragSelectCircleUtil.style([buttonDiv], G.options.buttonStartingStyle);
  DragSelectCircleUtil.style([buttonDiv], G.options.buttonStyle);
  buttonContainerDiv.appendChild(buttonDiv);
  return buttonDiv;
};

/**
 * Sets button mode to selecting or otherwise, changes CSS & HTML.
 * @param {String} mode Either "selecting" or not.
 */
DragSelectCircleControl.prototype.setButtonMode_ = function(mode){
  var G = this.globals;
  if (mode == 'selecting') {
    G.buttonDiv.innerHTML = G.options.buttonSelectingHTML;
    DragSelectCircleUtil.style([G.buttonDiv], G.options.buttonStartingStyle);
    DragSelectCircleUtil.style([G.buttonDiv], G.options.buttonSelectingStyle);
  } else {
    G.buttonDiv.innerHTML = G.options.buttonHTML;
    DragSelectCircleUtil.style([G.buttonDiv], G.options.buttonStartingStyle);
    DragSelectCircleUtil.style([G.buttonDiv], G.options.buttonStyle);
  }
};

/**
 * Called by GMap2's addOverlay method. Creates the select control
 * divs and appends to the map div.
 * @param {GMap2} map The map that has had this DragSelectCircleControl added to it.
 * @return {DOM Object} Div that holds the gselect-circlecontrol button
 */ 
DragSelectCircleControl.prototype.initialize = function(map) {
  var G = this.globals;
  var me = this; //This is required for some odd reason.
  var mapDiv = map.getContainer();
 
  //DOM:control buttons
  var buttonContainerDiv = document.createElement("div");	
  DragSelectCircleUtil.style([buttonContainerDiv], {cursor: 'pointer', zIndex: 150});
  var buttonDiv = this.initButton_(buttonContainerDiv);
  mapDiv.appendChild(buttonContainerDiv);
 
  //DOM:map covers
  var selectDiv = document.createElement("div");
  selectDiv.id = 'gselect-circle-map-cover';
  DragSelectCircleUtil.style([selectDiv], {position: 'absolute', display: 'none', overflow: 'hidden', cursor: 'crosshair', zIndex: 101});
  mapDiv.appendChild(selectDiv);
  G.mapCover = selectDiv;
  
  // add event listeners
  GEvent.addDomListener(buttonDiv, 'click', function(e) { me.buttonclick_(e); });
  GEvent.addDomListener(selectDiv, 'mousedown', function(e) { me.coverMousedown_(e); });
  GEvent.addDomListener(document, 'mousemove', function(e) { me.drag_(e); });
  GEvent.addDomListener(document, 'mouseup', function(e) { me.mouseup_(e); });

  // set globals
  G.mapPosition = DragSelectCircleUtil.getElementPosition(mapDiv);
  G.buttonDiv = DragSelectCircleUtil.gE("gselect-circle-control");
  G.map = map;
  
  G.borderCorrection = G.style.outlineWidth * 2;
  this.setDimensions_();
  
  //styles
  this.initStyles_();

  // disable text selection on map cover
  G.mapCover.onselectstart = function() {return false}; 
    
  return buttonContainerDiv;
};


/**
 * Required by GMaps API for controls. 
 * @return {GControlPosition} Default location for control
 */
DragSelectCircleControl.prototype.getDefaultPosition = function() {
  return new GControlPosition(G_ANCHOR_TOP_LEFT, new GSize(3, 85));
};

/**
 * Function called when mousedown event is captured.
 * @param {Object} e 
 */
DragSelectCircleControl.prototype.coverMousedown_ = function(e) {
  var G = this.globals;

  G.draggingOn = true;

  // update start position and draw prelim circle
  G.center = this.getCurrentLatLng(e);
  this.refreshMark_(e);

  // invoke the hook if provided
  if (G.hooks.dragstart != null) {
    G.hooks.dragstart(G.center);
  }
  return false;
};

/**
 * Function called when drag event is captured
 * @param {Object} e 
 */
DragSelectCircleControl.prototype.drag_ = function(e) {
  var G = this.globals;
  if (G.draggingOn) {

    this.refreshMark_(e);

    // invoke hook if provided
    if (G.hooks.dragging != null) {
      G.hooks.dragging(G.center, G.center.distanceFrom(this.getCurrentLatLng(e)));
    }
    return false;
  }
};


/** 
 * Function called when mouseup event is captured
 * @param {Event} e
 */
DragSelectCircleControl.prototype.mouseup_ = function(e){
  var G = this.globals;
  if (G.draggingOn) {
    G.draggingOn = false;
    this.resetDragSelectCircle_();

    this.refreshMark_(e);

    // invoke hook if provided
    if (G.hooks.dragend != null) {
      G.hooks.dragend(G.center, G.radius);
    }
  }
};

/**
 * Draw polyline on map for area bounded by a GLatLngBounds
 */
DragSelectCircleControl.prototype.mark_ = function(e) {
  var G = this.globals;
  var outer = this.getCurrentLatLng(e);
  var projection = G.map.getCurrentMapType().getProjection();
  var zoom = G.map.getZoom();
  var center_pt = projection.fromLatLngToPixel(G.center, zoom);
  var outer_pt = projection.fromLatLngToPixel(outer, zoom);
  circle_radius = Math.sqrt(Math.pow((outer_pt.x - center_pt.x), 2) + Math.pow((outer_pt.y - center_pt.y), 2));
  G.marker = this.drawCircle(G.center, circle_radius);
  G.radius = G.center.distanceFrom(outer);
}

DragSelectCircleControl.prototype.redraw = function(center, radius) {
  var G = this.globals;
  G.center = center;
  G.radius = radius;

  var arclen = radius / EARTH_RADIUS;
  var deltalng = Math.acos((Math.cos(arclen) - Math.pow(Math.sin(center.latRadians()), 2)) / Math.pow(Math.cos(center.latRadians()), 2));

  var outer = new GLatLng(G.center.lat(), (G.center.lngRadians() + deltalng) * 180 / Math.PI);
  var projection = G.map.getCurrentMapType().getProjection();
  var zoom = G.map.getZoom();
  var center_pt = projection.fromLatLngToPixel(G.center, zoom);
  var outer_pt = projection.fromLatLngToPixel(outer, zoom);
  var circle_radius = Math.sqrt(Math.pow((outer_pt.x - center_pt.x), 2) + Math.pow((outer_pt.y - center_pt.y), 2));
  G.marker = this.drawCircle(G.center, circle_radius);
}

DragSelectCircleControl.prototype.unmark_ = function() {
  var G = this.globals;
  if (G.marker != null) {
    G.map.removeOverlay(G.marker);
    G.marker = null;
  }
}

DragSelectCircleControl.prototype.refreshMark_ = function(e) {
  this.unmark_();
  this.mark_(e);
}

// DRAW CIRCLE
DragSelectCircleControl.prototype.drawCircle = function(point, radius) {
  var polyPoints = Array();
  
  var mapNormalProj = G_NORMAL_MAP.getProjection();
  var mapZoom = map.getZoom();
  var clickedPixel = mapNormalProj.fromLatLngToPixel(point, mapZoom);
  
  var polyNumSides = 20;
  var polySideLength = 18;
  var polyColor = "#0088ff";
  var polyRadius = radius; 
  
  for (var a = 0; a<(polyNumSides+1); a++) {
    var aRad = polySideLength*a*(Math.PI/180);
    var pixelX = clickedPixel.x + polyRadius * Math.cos(aRad);
    var pixelY = clickedPixel.y + polyRadius * Math.sin(aRad);
    var polyPixel = new GPoint(pixelX,pixelY);
    var polyPoint = mapNormalProj.fromPixelToLatLng(polyPixel,mapZoom);
    polyPoints.push(polyPoint);
  }
  var circle = new GPolygon(polyPoints,"#0088ff",2,.5,polyColor,.5);
  map.addOverlay(circle);
  return circle;
}

/**
 * Set the cover sizes according to the size of the map
 */
DragSelectCircleControl.prototype.setDimensions_ = function() {
  var G = this.globals;
  var mapSize = G.map.getSize();
  G.mapWidth  = mapSize.width;
  G.mapHeight = mapSize.height;
  DragSelectCircleUtil.style([G.mapCover], {top: '0', left: '0', width: G.mapWidth + 'px', height: G.mapHeight + 'px'});
};

/**
 * Initializes styles based on global parameters
 */
DragSelectCircleControl.prototype.initStyles_ = function(){
};

/**
 * Function called when the select button's click event is captured.
 */
DragSelectCircleControl.prototype.buttonclick_ = function(){
  var G = this.globals;	
  if (G.mapCover.style.display == 'block') { // reset if clicked before dragging 
    this.resetDragSelectCircle_();
  } else {
    this.initCover_();
  }

  //invoke hook if provided
  if (G.hooks['buttonclick'] != null){
    G.hooks.buttonclick(G.draggingOn);
  }
};

/**
 * Shows the cover over the map
 */
DragSelectCircleControl.prototype.initCover_ = function(){
  var G = this.globals;
  G.mapPosition = DragSelectCircleUtil.getElementPosition(G.map.getContainer());
  this.setDimensions_();
  this.setButtonMode_('selecting');
  DragSelectCircleUtil.style([G.mapCover], {display: 'block'});
};

/**
 * Gets position of the mouse relative to the map
 * @param {Object} e
 */
DragSelectCircleControl.prototype.getRelPos_ = function(e) {
  var pos = DragSelectCircleUtil.getMousePosition(e);
  var mapPos = this.globals.mapPosition;
  return new GPoint(pos.x - mapPos.x, pos.y - mapPos.y);
};

DragSelectCircleControl.prototype.getCurrentLatLng = function(e) {
  var G = this.globals;
  return G.map.fromContainerPixelToLatLng(this.getRelPos_(e));
}

/** 
 * Resets CSS and button display when drag select done
 */
DragSelectCircleControl.prototype.resetDragSelectCircle_ = function() {
  var G = this.globals;
  DragSelectUtil.style([G.mapCover], {display: 'none'});
  this.setButtonMode_('normal');
};

/* utility functions in DragSelectCircleUtil.namespace */
var DragSelectCircleUtil={};

/**
Alias function for getting element by id
@param {String} sId
@return {Object} DOM object with sId id
*/
DragSelectCircleUtil.gE = function(sId) { return document.getElementById(sId); }

/**
A general-purpose function to get the absolute position of the mouse.
@param {Object} e  Mouse event
@return {Object} Describes position
*/
DragSelectCircleUtil.getMousePosition = function(e) {
  var posX = 0;
  var posY = 0;
  if (!e) var e = window.event;
  if (e.pageX || e.pageY) {
    posX = e.pageX;
    posY = e.pageY;
  } else if (e.clientX || e.clientY){
    posX = e.clientX + 
      (document.documentElement.scrollLeft ? document.documentElement.scrollLeft : document.body.scrollLeft);
    posY = e.clientY + 
      (document.documentElement.scrollTop ? document.documentElement.scrollTop : document.body.scrollTop);
  }	
  return new GPoint(posX, posY);  
};

/**
Gets position of element
@param {Object} element
@return {Object} Describes position
*/
DragSelectCircleUtil.getElementPosition = function(element) {
  var leftPos = element.offsetLeft;        // initialize var to store calculations
  var topPos = element.offsetTop;          // initialize var to store calculations
  var parElement = element.offsetParent;   // identify first offset parent element  
  while (parElement != null ) {            // move up through element hierarchy
    leftPos += parElement.offsetLeft;      // appending left offset of each parent
    topPos += parElement.offsetTop;  
    parElement = parElement.offsetParent;  // until no more offset parents exist
  }
  return new GPoint(leftPos, topPos);
};

/**
 * Applies styles to DOM objects 
 * @param {String/Object} elements Either comma-delimited list of ids 
 *   or an array of DOM objects
 * @param {Object} styles Hash of styles to be applied
 */
DragSelectCircleUtil.style = function(elements, styles){
  if (typeof(elements) == 'string') {
    elements = DragSelectCircleUtil.getManyElements(elements);
  }
  for (var i = 0; i < elements.length; i++) {
    for (var s in styles) { 
      elements[i].style[s] = styles[s];
    }
  }
};

/**
 * Gets DOM elements array according to list of IDs
 * @param {String} elementsString Comma-delimited list of IDs
 * @return {Array} Array of DOM elements corresponding to s
 */
DragSelectCircleUtil.getManyElements = function(idsString){		
  var idsArray = idsString.split(',');
  var elements = [];
  for (var i = 0; i < idsArray.length; i++){
    elements[elements.length] = DragSelectCircleUtil.gE(idsArray[i])
  };
  return elements;
};
