//show a lat/lon graticule www.bdcc.co.uk Bill Chadwick 2006 Free for any use
function LatLonGraticule(sexagesimal) {
    this.sex_ = sexagesimal || false;//default is decimal intervals
}
LatLonGraticule.prototype = new GOverlay();
LatLonGraticule.prototype.initialize = function(map) {
  this.map_ = map;
  this.divs_ = new Array(); //array for divs used for lines and labels
  this.mapPane = this.map_.getPane(G_MAP_MARKER_SHADOW_PANE);
}
LatLonGraticule.prototype.copy = function() { return new LatLonGraticule(this.sex_); }
LatLonGraticule.prototype.remove = function() {
	try{
		var i = 0;
		for(i=0; i<this.divs_.length; i++)
			this.mapPane.removeChild(this.divs_[i]);
	}
	catch(e){}
}
// Redraw the graticule based on the current projection and zoom level
LatLonGraticule.prototype.redraw = function(force) {
  this.remove(); //clear old

  //best color for writing on the map
  this.color_ = this.map_.getCurrentMapType().getTextColor();

  var bnds = this.map_.getBounds(); //determine graticule interval
  var l = bnds.getSouthWest().lng();
  var b = bnds.getSouthWest().lat();
  var t = bnds.getNorthEast().lat();
  var r = bnds.getNorthEast().lng();

  //sanity
  if(b < -90.0) b = -90.0;
  if(t > 90.0) t = 90.0;
  if(l < -180.0) l = -180.0;  
  if(r > 180.0) r = 180.0;
  if(l == r){
	l = -180.0;
	r = 180.0;
  }
  if(t == b){
	b = -90.0;
	t = 90.0;
  }

  //grid interval in degrees
  var dLat = this.gridIntervalMins(t-b)/60;
  var dLng = 1/60; 
  if(r>l)
	dLng *= this.gridIntervalMins(r-l);
  else
	dLng *= this.gridIntervalMins((180-l)+(r+180));

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
  var i=0;//count inserted divs

  //min and max x and y pixel values for graticule lines
  var pbl = this.map_.fromLatLngToDivPixel(new GLatLng(b,l));
  var ptr = this.map_.fromLatLngToDivPixel(new GLatLng(t,r));
  
  this.maxX = ptr.x;
  this.maxY = pbl.y;
  this.minX = pbl.x;
  this.minY = ptr.y;
  
  var makeLabel = function(x, y) {
	var d = document.createElement("DIV");
	d.style.position = "absolute";
	d.style.left = x.toString() + "px";
	d.style.top = y.toString() + "px";
	d.style.color = this.color_;
	d.style.fontFamily='Arial';
	d.style.fontSize='x-small';
	return d;
  };

  var x;//coord for label
  //labels on second column to avoid peripheral controls
  var y = this.map_.fromLatLngToDivPixel(new GLatLng(b+dLat+dLat,l)).y + 2;//coord for label
  
  var lo = l;//copy to save original
  
  if(r<lo)
      r += 360.0;

  //vertical lines
  while(lo<=r){
	var p = this.map_.fromLatLngToDivPixel(new GLatLng(b,lo));

	//line
	this.divs_[i] = this.createVLine(p.x);
	this.mapPane.insertBefore(this.divs_[i],null);
	i++;
	
	//label	 
	x = p.x +3;
	var d = makeLabel(x, y);
	if(this.sex_){
		var degs = Math.floor(lo); 
		var mins = ((Math.abs(lo)-degs)*60.0).toFixed(2);
		if(mins == "60.00"){
			degs += 1.0;
			mins = "0.00";
		}
		d.innerHTML= degs + ":" + mins; 
        }
	else{
		d.innerHTML = lo.toFixed(lonDecs);// only significant digits
	}
	if(lo<0)
		d.title = "West (WGS84)";
	else 
		d.title = "East (WGS84)";
	this.mapPane.insertBefore(d,null);
	
	this.divs_[i] = d;//save for remove
	i++;// next
	lo += dLng;	
	if (lo > 180.0){
		r -= 360.0;
		lo -= 360.0;
	}	
  }
  
  var j = 0;// count lines
      
  //labels on second row to avoid controls
  x = this.map_.fromLatLngToDivPixel(new GLatLng(b,l+dLng+dLng)).x + 3;
  
  //horizontal lines
  while(b<=t){
	var p = this.map_.fromLatLngToDivPixel(new GLatLng(b,l));

	//line
	if(r < l){ //draw lines across the dateline
		this.divs_[i] = this.createHLine3(b); }
	else if (r == l){ //draw lines for world scale zooms
		this.divs_[i] = this.createHLine3(b);
		}
	else{
		this.divs_[i] = this.createHLine(p.y);
		}
	this.mapPane.insertBefore(this.divs_[i],null);
	i++;
			
	//label
	y = p.y + 2;
	var d = makeLabel(x, y);
	if(this.sex_){
		var degs = Math.floor(Math.abs(b)); 
		var mins = ((Math.abs(b)-degs)*60.0).toFixed(2);
		if(mins == "60.00"){
			degs += 1.0;
			mins = "0.00";
			}
		d.innerHTML= degs + ":" + mins; 
        }
	else{
		d.innerHTML = b.toFixed(latDecs);// only significant digits
		}
	if(b<0)
		d.title = "South (WGS84)";
	else 
		d.title = "North (WGS84)";

	if(j != 2){//dont put two labels in the same place
		this.mapPane.insertBefore(d,null);
		this.divs_[i] = d; // save for remove
		i++;
		}
	
	j++;//next
	b += dLat; 
  }
}

LatLonGraticule.prototype.gridIntervalMins = function(dDeg) {
	if(this.sex_)
		return this.gridIntervalSexMins(dDeg)
	return this.gridIntervalDecMins(dDeg)
}

//calculate rounded graticule interval in decimals of degrees for supplied lat/lon span
//return is in minutes
LatLonGraticule.prototype.gridIntervalDecMins = function(dDeg) {
	var dDeg = dDeg/10;//want around 10 lines in the graticule
	dDeg *= 6000;//to minutes*100
	dDeg = Math.ceil(dDeg)/100;//minutes and hundredths of mins
	
	if(dDeg <= 0.06)
	      dDeg = 0.06;//0.001 degrees
	else if(dDeg <= 0.12)
	      dDeg = 0.12;//0.002 degrees
	else if(dDeg <= 0.3)
	      dDeg = 0.3;//0.005 degrees
	else if(dDeg <= 0.6)
	      dDeg = 0.6;//0.01 degrees
	else if (dDeg <=  1.2)
	      dDeg = 1.2;//0.02 degrees
	else if(dDeg <= 3)
	      dDeg = 3;//0.05 degrees
	else if(dDeg <= 6)
	      dDeg = 6;//0.1 degrees
	else if (dDeg <=  12)
	      dDeg = 12;//0.2 degrees
	else if (dDeg <=  30)
	      dDeg = 30;//0.5
	else if (dDeg <=  60)
	      dDeg = 60;//1
	else if (dDeg <=  (60*2))
	      dDeg = 60*2;
	else if (dDeg <=  (60*5))
	      dDeg = 60*5;
	else if (dDeg <=  (60*10))
	      dDeg = 60*10;
	else if (dDeg <=  (60*20))
	      dDeg = 60*20;
	else if (dDeg <=  (60*30))
	      dDeg = 60*30;
	else
	      dDeg = 60*45;
	
	return dDeg;
}

//calculate rounded graticule interval in Minutes for supplied lat/lon span
//return is in minutes
LatLonGraticule.prototype.gridIntervalSexMins = function(dDeg) {

  var dDeg = dDeg/10;//want around 10 lines in the graticule
  dDeg *= 6000;//to minutes*100
  dDeg = Math.ceil(dDeg)/100;//minutes and hundredths of mins
  
  if(dDeg <= 0.01) 
        dDeg = 0.01;//0.01 minutes 
  else if(dDeg <= 0.02) 
        dDeg = 0.02;//0.02 minutes 
  else if(dDeg <= 0.05) 
        dDeg = 0.05;//0.05 minutes 
  else if(dDeg <= 0.1) 
        dDeg = 0.1;//0.1 minutes 
  else if(dDeg <= 0.2) 
        dDeg = 0.2;//0.2 minutes 
  else if(dDeg <= 0.5) 
        dDeg = 0.5;//0.5 minutes 
  else if(dDeg <= 1.0) 
        dDeg = 1.0;//1.0 minute 
  else if(dDeg <= 3)
	dDeg = 3;//0.05 degrees
  else if(dDeg <= 6)
	dDeg = 6;//0.1 degrees
  else if (dDeg <=  12)
	dDeg = 12;//0.2 degrees
  else if (dDeg <=  30)
	dDeg = 30;//0.5
  else if (dDeg <=  60)
	dDeg = 60;//1
  else if (dDeg <=  (60*2))
	dDeg = 60*2;
  else if (dDeg <=  (60*5))
	dDeg = 60*5;
  else if (dDeg <=  (60*10))
	dDeg = 60*10;
  else if (dDeg <=  (60*20))
	dDeg = 60*20;
  else if (dDeg <=  (60*30))
	dDeg = 60*30;
  else
	dDeg = 60*45;
  
  return dDeg;

}

//calculate grid label precision from decimal grid interval in degrees
LatLonGraticule.prototype.gridPrecision = function(dDeg) {
	if(dDeg < 0.01)
		return 3;
	else if(dDeg < 0.1)
		return 2;
	else if(dDeg < 1)
		return 1;
}
  
//returns a div that is a vertical single pixel line    	  
LatLonGraticule.prototype.createVLine = function(x) {
	var div = document.createElement("DIV");
	div.style.position = "absolute";
	div.style.overflow = "hidden";
	div.style.backgroundColor = this.color_;
	div.style.left = x + "px";
	div.style.top = this.minY + "px";
	div.style.width = "1px";
	div.style.height = (this.maxY-this.minY) + "px";
	return div;
}

//returns a div that is a horizontal single pixel line    	  
LatLonGraticule.prototype.createHLine = function(y) {
	var div = document.createElement("DIV");
	div.style.position = "absolute";
	div.style.overflow = "hidden";
	div.style.backgroundColor = this.color_;
	div.style.left = this.minX + "px";
	div.style.top = y + "px";
	div.style.width = (this.maxX-this.minX) + "px";
	div.style.height = "1px";
	return div;
}

//returns a div that is a horizontal single pixel line, across the dateline  
//we find the start and width of a 180 degree line and draw the same amount to its left and right	  
LatLonGraticule.prototype.createHLine3 = function(lat) {
	var f = this.map_.fromLatLngToDivPixel(new GLatLng(lat,0));
	var t = this.map_.fromLatLngToDivPixel(new GLatLng(lat,180));		
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
