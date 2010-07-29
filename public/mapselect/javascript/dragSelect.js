/*
* DragSelectControl Class
* Adapted from DragZoomControl under fair use as a Derivative Work:
* Licensed under the Apache License, Version 2.0 (the "License") you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

/**
 * Constructor for DragSelectControl, which takes 3 option hashes and
 *  uses them to customize the control.
 * @param {opts_boxStyle} Named optional arguments:
 *   opts_boxStyle.opacity {Number} Opacity from 0-1
 *   opts_boxStyle.fillColor {String} Hex value of fill color
 *   opts_boxStyle.border {String} CSS-style declaration of border
 * @param {opts_other} Named optional arguments:
 *   opts_other.buttonHTML {String} The select button HTML in non-activated state
 *   opts_other.buttonStartingStyle {Object} A hash of css styles for the 
 *     select button which are common to both un-activated and activated state
 *   opts_other.buttonStyle {Object} A hash of css styles for the select button 
 *     which will be applied when the button is in un-activated state.
 *   opts_other.buttonSelectingHTML {String} HTML which is placed in the 
 *     select button when the button is activated. 
 *   opts_other.buttonSelectingStyle {Object} A hash of css styles for the 
 *    select button which will be applied when the button is activated.
 *   opts_other.overlayRemoveTime {Number} The number of milliseconds to wait before
 *     removing the rectangle indicating the selected-in area after the select has happened.
 *   opts_other.stickySelectEnabled {Boolean} Whether or not the control stays in 
 *     "select mode" until turned off. When true, the user can select repeatedly, 
 *     until clicking on the select button again to turn select mode off.
 *   opts_other.backButtonEnabled {Boolean} enables Back Button functionality
 *   opts_other.backButtonHTML {String} The back button HTML
 *   opts_other.backButtonStyle {Object} A hash of css styles for the back button
 *     which will be applied when the button is created.	
 * @param {opts_callbacks} Named optional arguments:
 *   opts_callbacks.buttonclick {Function} Called when the DragSelect is activated 
 *     by clicking on the "select" button. 
 *   opts_callbacks.dragstart {Function} Called when user starts to drag a rectangle.
 *     Callback args are x,y -- the PIXEL values, relative to the upper-left-hand 
 *     corner of the map, where the user began dragging.
 *   opts_callbacks.dragging {Function} Called repeatedly while the user is dragging.
 *     Callback args are startX,startY, width,height--the PIXEL values of the 
 *     start of the drag, and the current drag point, respectively.
 *   opts_callbacks.dragend {Function} Called when the user releases the mouse button 
 *     after dragging the rectangle. Callback args are: NW {GLatLng}, NE {GLatLng}, 
 *     SE {GLatLng}, SW {GLatLng}, NW {GPoint}, NE {GPoint}, SE {GPoint}, SW {GPoint}.
 *     The first 4 are the latitudes/longitudes; the last 4 are the pixel coords on the map.
 *   opts_callbacks.backbuttonclick {Function} Called when the back button is activated 
 *     after the map context is restored. Callback args: methodCall (boolean) set true if
 *     this backbuttonclick was to restore context set by the mathod call, else false.
 * Method
 *    this.saveMapContext(text) Call to push map context onto the backStack and set the button text 
 *    this.initiateSelect() Call to simulate clicking the dragSelect button
 *    this.initiateSelectBack() Call to simulate clicking the dragSelect back button
 **/

function DragSelectControl(opts_boxStyle, opts_other, opts_callbacks) {
  // Holds all information needed globally
  // Not all globals are initialized here
  this.globals = {
    draggingOn: false,
    mapPosition: null,
    outlineDiv: null,
    mapWidth: 0,
    mapHeight: 0,
    mapRatio: 0,
    startX: 0,
    startY: 0,
    borderCorrection: 0
  };

  //box style options
  this.globals.style = {
    opacity: .2,
    fillColor: "#000",
    border: "2px solid #f00"
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
    backButtonHTML: 'select back',
    backButtonStyle: {background: '#FFF', display: 'none'},
    buttonSelectingHTML: 'Drag a region on the map',
    buttonSelectingStyle: {background: '#FF0'},
    overlayRemoveTime: 6000,
    backButtonEnabled: false,
    stickySelectEnabled: false
  };
	
  for (var s in opts_other) {
    this.globals.options[s] = opts_other[s]
  }

  // callbacks: buttonclick, dragstart, dragging, dragend, backbuttonclick 
  if (opts_callbacks == null) {
    opts_callbacks = {}
  }
  this.globals.callbacks = opts_callbacks;
}

DragSelectControl.prototype = new GControl();

/**
 * Methods
 */

/**
 * Method called to save the map context before the select.
 * Back Button functionality:	
 * @param {text} text string for the back button
 */
DragSelectControl.prototype.saveMapContext = function(text) {
  if (this.globals.options.backButtonEnabled) {
    this.saveBackContext_(text,true);
    this.globals.backButtonDiv.style.display = 'block';
  }	
};

/**
 * Initiate a dragSelect as if the user had.
 */
DragSelectControl.prototype.initiateSelect = function() {this.buttonclick_()};

/**
 * Initiate a dragSelect back operation as if the user had.
 * Back Button functionality:	
 */
DragSelectControl.prototype.initiateSelectBack = function() {if (this.globals.options.backButtonEnabled) this.backbuttonclick_()};	

/**
 * Creates a new button to control gselect and appends to the button container div.
 * @param {DOM Node} buttonContainerDiv created in main .initialize code
 */
DragSelectControl.prototype.initButton_ = function(buttonContainerDiv) {
  var G = this.globals;
  var buttonDiv = document.createElement('div');
  buttonDiv.innerHTML = G.options.buttonHTML;
  buttonDiv.id = 'gselect-control';
  DragSelectUtil.style([buttonDiv], {cursor: 'pointer', zIndex:200});
  DragSelectUtil.style([buttonDiv], G.options.buttonStartingStyle);
  DragSelectUtil.style([buttonDiv], G.options.buttonStyle);
  buttonContainerDiv.appendChild(buttonDiv);
  return buttonDiv;
};

/**
 * Creates a second new button to control backup select and appends to the button container div.
 * @param {DOM Node} buttonContainerDiv created in main .initialize code
 */
DragSelectControl.prototype.initBackButton_ = function(buttonContainerDiv) {
  var G = this.globals;
  var backButtonDiv = document.createElement('div');
  backButtonDiv.innerHTML = G.options.backButtonHTML;
  backButtonDiv.id = 'gselect-back';
  DragSelectUtil.style([backButtonDiv], {cursor: 'pointer', zIndex:200});
  DragSelectUtil.style([backButtonDiv], G.options.buttonStartingStyle);
  DragSelectUtil.style([backButtonDiv], G.options.backButtonStyle);
  buttonContainerDiv.appendChild(backButtonDiv);
  return backButtonDiv;
};

/**
 * Sets button mode to selecting or otherwise, changes CSS & HTML.
 * @param {String} mode Either "selecting" or not.
 */
DragSelectControl.prototype.setButtonMode_ = function(mode){
  var G = this.globals;
  if (mode == 'selecting') {
    G.buttonDiv.innerHTML = G.options.buttonSelectingHTML;
    DragSelectUtil.style([G.buttonDiv], G.options.buttonStartingStyle);
    DragSelectUtil.style([G.buttonDiv], G.options.buttonSelectingStyle);
  } else {
    G.buttonDiv.innerHTML = G.options.buttonHTML;
    DragSelectUtil.style([G.buttonDiv], G.options.buttonStartingStyle);
    DragSelectUtil.style([G.buttonDiv], G.options.buttonStyle);
  }
};

/**
 * Called by GMap2's addOverlay method. Creates the select control
 * divs and appends to the map div.
 * @param {GMap2} map The map that has had this DragSelectControl added to it.
 * @return {DOM Object} Div that holds the gselectcontrol button
 */ 
DragSelectControl.prototype.initialize = function(map) {
  var G = this.globals;
  var me = this;
  var mapDiv = map.getContainer();
 
  //DOM:control buttons
  var buttonContainerDiv = document.createElement("div");	
  DragSelectUtil.style([buttonContainerDiv], {cursor: 'pointer', zIndex: 150});
  var buttonDiv = this.initButton_(buttonContainerDiv);
  var backButtonDiv = this.initBackButton_(buttonContainerDiv);
  mapDiv.appendChild(buttonContainerDiv);
 
  //DOM:map covers
  var selectDiv = document.createElement("div");
  selectDiv.id = 'gselect-map-cover';
  DragSelectUtil.style([selectDiv], {position: 'absolute', display: 'none', overflow: 'hidden', cursor: 'crosshair', zIndex: 101});
  selectDiv.innerHTML ='<div id="gselect-outline" style="position:absolute;display:none;"></div>';
  mapDiv.appendChild(selectDiv);
  
  // add event listeners
  GEvent.addDomListener(buttonDiv, 'click', function(e) {
    me.buttonclick_(e);
  });
  GEvent.addDomListener(backButtonDiv, 'click', function(e) {
    me.backbuttonclick_(e);
  });
  GEvent.addDomListener(selectDiv, 'mousedown', function(e) {
    me.coverMousedown_(e);
  });
  GEvent.addDomListener(document, 'mousemove', function(e) {
    me.drag_(e);
  });
  GEvent.addDomListener(document, 'mouseup', function(e) {
    me.mouseup_(e);
  });
  
  // set globals
    G.mapPosition = DragSelectUtil.getElementPosition(mapDiv);
    G.outlineDiv = DragSelectUtil.gE("gselect-outline");	
    G.buttonDiv = DragSelectUtil.gE("gselect-control");
    G.backButtonDiv = DragSelectUtil.gE("gselect-back");
    G.mapCover = DragSelectUtil.gE("gselect-map-cover");
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
DragSelectControl.prototype.getDefaultPosition = function() {
  return new GControlPosition(G_ANCHOR_TOP_LEFT, new GSize(3, 50));
};

/**
 * Function called when mousedown event is captured.
 * @param {Object} e 
 */
DragSelectControl.prototype.coverMousedown_ = function(e){
  var G = this.globals;
  G.draggingOn = true;
  this.unmark_();

  // update start position
  var pos = this.getRelPos_(e);
  G.startX = pos.left;
  G.startY = pos.top;

  //cover map
//  DragSelectUtil.style([G.mapCover], {background: 'transparent', opacity: 1, filter: 'alpha(opacity=100)'});
  DragSelectUtil.style([G.outlineDiv], {left: G.startX + 'px', top: G.startY + 'px', display: 'block', width: '1px', height: '1px'});

  // invoke the callback if provided
  if (G.callbacks.dragstart != null) {
    G.callbacks.dragstart(G.startX, G.startY);
  }
  return false;
};

/**
 * Function called when drag event is captured
 * @param {Object} e 
 */
DragSelectControl.prototype.drag_ = function(e){
  var G = this.globals;
  if(G.draggingOn) {
    var pos = this.getRelPos_(e);
    var startX = Math.min(G.startX, pos.left);
    var startY = Math.min(G.startY, pos.top);
    var width = Math.abs(pos.left - G.startX);
    var height = Math.abs(pos.top - G.startY);

    DragSelectUtil.style([G.outlineDiv], {left: startX + 'px', top: startY + 'px', display: 'block', width: width + 'px', height: height + 'px'});	

    // invoke callback if provided
    if (G.callbacks.dragging != null) {
      G.callbacks.dragging(startX, startY, startX + width, startY + height)
    }
		
    return false;
  }  
};

/** 
 * Function called when mouseup event is captured
 * @param {Event} e
 */
DragSelectControl.prototype.mouseup_ = function(e){
  var G = this.globals;
  if (G.draggingOn) {
    G.draggingOn = false;

    this.resetDragSelect_();

    // determine selection
    var rect = this.getRectangle_(G.startX, G.startY, this.getRelPos_(e), 1);
    var sw_point = null;
    var ne_point = null;
    //four cases

    if (rect.width < 0) {//went left
	    if (rect.endY > rect.startY) {
		    sw_point = new GPoint(rect.endX, rect.endY);
		    ne_point = new GPoint(rect.startX, rect.startY);
	    } else {
		    sw_point = new GPoint(rect.endX, rect.startY);
		    ne_point = new GPoint(rect.startX, rect.endY);
	    }
    } else {
	    if (rect.endY > rect.startY) { // went down
		    sw_point = new GPoint(rect.startX, rect.endY);
		    ne_point = new GPoint(rect.endX, rect.startY);
	    } else {
		    sw_point = new GPoint(rect.startX, rect.startY);
		    ne_point = new GPoint(rect.endX, rect.endY);
	    }
    }

//    var start = G.map.fromContainerPixelToLatLng(new GPoint(rect.startX, rect.startY)); 
//    var end = G.map.fromContainerPixelToLatLng(new GPoint(rect.endX, rect.endY)); 
	var sw = G.map.fromContainerPixelToLatLng(sw_point);
	var ne = G.map.fromContainerPixelToLatLng(ne_point);

    var selection = new GLatLngBounds(sw, ne);

    this.mark_(selection);

    // invoke callback if provided
    if (G.callbacks.dragend != null) {
      G.callbacks.dragend(selection);
    }

    //re-init if sticky
    if (G.options.stickySelectEnabled) {
      this.initCover_();
      if (G.options.backButtonEnabled) {
	this.saveBackContext_(G.options.backButtonHTML, false); // save the map context for back button
      }
      G.backButtonDiv.style.display='none';
    }
  }
};

/**
 * Draw polyline on map for area bounded by a GLatLngBounds
 */
DragSelectControl.prototype.mark_ = function(bounds) {
  var G = this.globals;
  var interlng = bounds.getCenter().lng();
  var interlat = bounds.getCenter().lat();

  var ne = bounds.getNorthEast();
  var sw = bounds.getSouthWest();
  var nw = new GLatLng(ne.lat(), sw.lng());
  var se = new GLatLng(sw.lat(), ne.lng());

  var n = new GLatLng(nw.lat(), interlng);
  var s = new GLatLng(sw.lat(), interlng);
  var e = new GLatLng(interlat, se.lng());
  var w = new GLatLng(interlat, sw.lng());

  var polyline = new GPolyline([nw, n, ne, e, se, s, sw, w, nw], G.style.outlineColor, G.style.outlineWidth, 0.6);
  G.map.addOverlay(polyline);
  G.marker = polyline;
}

DragSelectControl.prototype.unmark_ = function() {
	var G = this.globals;
	if (G.marker != null) {
		G.map.removeOverlay(G.marker);
		G.marker = null;
	}
}

/**
 * Set the cover sizes according to the size of the map
 */
DragSelectControl.prototype.setDimensions_ = function() {
  var G = this.globals;
  var mapSize = G.map.getSize();
  G.mapWidth  = mapSize.width;
  G.mapHeight = mapSize.height;
  DragSelectUtil.style([G.mapCover], 
    {top: '0', left: '0', width: G.mapWidth + 'px', height: G.mapHeight +'px'});
};

/**
 * Initializes styles based on global parameters
 */
DragSelectControl.prototype.initStyles_ = function(){
  var G = this.globals;
//  DragSelectUtil.style([G.mapCover], {filter: G.style.alphaIE, opacity: G.style.opacity, background:G.style.fillColor});
  G.outlineDiv.style.border = G.style.border;  
};

/**
 * Function called when the select button's click event is captured.
 */
DragSelectControl.prototype.buttonclick_ = function(){
  var G = this.globals;	
  G.backButtonDiv.style.display='none';
  if (G.mapCover.style.display == 'block') { // reset if clicked before dragging 
    this.resetDragSelect_();
    if (G.options.backButtonEnabled) {  
      this.restoreBackContext_();  // pop the backStack on a button reset
      if (G.backStack.length==0) G.backButtonDiv.style.display='none';
    }
  } else {
    this.initCover_();
    if ( G.options.backButtonEnabled ) this.saveBackContext_(G.options.backButtonHTML,false); // save the map context for back button
  }

  //invoke callback if provided
  if(G.callbacks['buttonclick'] != null){
    G.callbacks.buttonclick();
  }
};

/**
 * Back Button functionality:	
 * Function called when the back button's click event is captured.
 * calls the function to set the map context back to where it was before the select.
 */
DragSelectControl.prototype.backbuttonclick_ = function(){
  var G = this.globals;	
  if (G.options.backButtonEnabled && G.backStack.length > 0) {
    this.restoreBackContext_();
    // invoke the callback if provided
    if (G.callbacks['backbuttonclick'] != null) {
      G.callbacks.backbuttonclick(G.methodCall);
    }
  }
};

/** 
 * Back Button functionality:	
 * Saves the map context and pushes it on the backStack for later use by the back button
 */
DragSelectControl.prototype.saveBackContext_ = function(text,methodCall) {
  var G = this.globals;
  var backFrame = {};
  backFrame["center"] = G.map.getCenter();
  backFrame["select"] = G.map.getSelect();
  backFrame["maptype"] = G.map.getCurrentMapType();
  backFrame["text"] = G.backButtonDiv.innerHTML; // this saves the previous button text
  backFrame["methodCall"] = methodCall; //This determines if it was an internal or method call
  G.backStack.push(backFrame);
  G.backButtonDiv.innerHTML = text;
  // Back Button is turned on in resetDragSelect_()
};

/** 
 * Back Button functionality:	
 * Pops the previous map context off of the backStack and restores the map to that context
 */
DragSelectControl.prototype.restoreBackContext_ = function() {
  var G = this.globals;
  var backFrame = G.backStack.pop();
  G.map.setCenter(backFrame["center"],backFrame["select"],backFrame["maptype"]);
  G.backButtonDiv.innerHTML = backFrame["text"];
  G.methodCall = backFrame["methodCall"];
  if (G.backStack.length==0) G.backButtonDiv.style.display = 'none'; // if we're at the top of the stack, hide the back botton
};

/**
 * Shows the cover over the map
 */
DragSelectControl.prototype.initCover_ = function(){
  var G = this.globals;
  G.mapPosition = DragSelectUtil.getElementPosition(G.map.getContainer());
  this.setDimensions_();
  this.setButtonMode_('selecting');
  DragSelectUtil.style([G.mapCover], {display: 'block'});
  DragSelectUtil.style([G.outlineDiv], {width: '0px', height: '0px'});

};

/**
 * Gets position of the mouse relative to the map
 * @param {Object} e
 */
DragSelectControl.prototype.getRelPos_ = function(e) {
  var pos = DragSelectUtil.getMousePosition(e);
  var mapPos = this.globals.mapPosition;
  return {top: (pos.top - mapPos.top), 
          left: (pos.left - mapPos.left)};
};

/**
 * Figures out the rectangle the user's drawing.
 * @param {Number} startX 
 * @param {Number} startY
 * @param {Object} currPos
 * @return {Object} Describes the rectangle
 */
DragSelectControl.prototype.getRectangle_ = function(startX, startY, currPos, ratio){
  var dX = currPos.left - startX;
  var dY = currPos.top - startY;	
  return {
    startX: startX, startY: startY,
    endX: currPos.left, endY: currPos.top,
    width: dX, height: dY,
  }
};

/** 
 * Resets CSS and button display when drag select done
 */
DragSelectControl.prototype.resetDragSelect_ = function() {
  var G = this.globals;
  DragSelectUtil.style([G.mapCover], {display: 'none'});
  G.outlineDiv.style.display = 'none';	
  this.setButtonMode_('normal');
  if (G.options.backButtonEnabled  && (G.backStack.length > 0)) G.backButtonDiv.style.display = 'block'; // show the back button
};

/* utility functions in DragSelectUtil.namespace */
var DragSelectUtil={};

/**
 * Alias function for getting element by id
 * @param {String} sId
 * @return {Object} DOM object with sId id
 */
DragSelectUtil.gE = function(sId) {
  return document.getElementById(sId);
}

/**
 * A general-purpose function to get the absolute position of the mouse.
 * @param {Object} e  Mouse event
 * @return {Object} Describes position
 */
DragSelectUtil.getMousePosition = function(e) {
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
  return {left: posX, top: posY};  
};

/**
 * Gets position of element
 * @param {Object} element
 * @return {Object} Describes position
 */
DragSelectUtil.getElementPosition = function(element) {
  var leftPos = element.offsetLeft;          // initialize var to store calculations
  var topPos = element.offsetTop;            // initialize var to store calculations
  var parElement = element.offsetParent;     // identify first offset parent element  
  while (parElement != null ) {                // move up through element hierarchy
    leftPos += parElement.offsetLeft;      // appending left offset of each parent
    topPos += parElement.offsetTop;  
    parElement = parElement.offsetParent;  // until no more offset parents exist
  }
  return {left: leftPos, top: topPos};
};

/**
 * Applies styles to DOM objects 
 * @param {String/Object} elements Either comma-delimited list of ids 
 *   or an array of DOM objects
 * @param {Object} styles Hash of styles to be applied
 */
DragSelectUtil.style = function(elements, styles){
  if (typeof(elements) == 'string') {
    elements = DragSelectUtil.getManyElements(elements);
  }
  for (var i in elements) {
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
DragSelectUtil.getManyElements = function(idsString){		
  var idsArray = idsString.split(',');
  var elements = [];
  for (var i = 0; i < idsArray.length; i++){
    elements[elements.length] = DragSelectUtil.gE(idsArray[i])
  };
  return elements;
};
