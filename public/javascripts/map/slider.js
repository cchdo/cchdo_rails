var Slider = {
	minVal: 1975,
	maxVal: new Date().getFullYear(),
	length: 200,
	sliding: false
};
Slider.$ = function(id){return document.getElementById(id);};
Slider.$$ = function(classname){return document.getElementsByClassName(classname);};
Slider.init = function() {
	this.slider = Slider.$$("slider")[0];
	this.cover = Slider.$("cover");
	this.cover.style.left = "0px";
	this.cover.style.width = this.length + "px";
	this.ptrL = Slider.$$("point_left")[0];
	this.ptrR = Slider.$$("point_right")[0];
	this.slideRatio = this.length/(1.0*this.maxVal-this.minVal);
	this.currCoverWidth = this.length;
	this.x; // current event's x position
	this.activept;
	this.ptrL;
	this.ptrR;
}
Slider.sliderValue = function(point) { return Math.round(Slider.minVal + Slider.pointValue(point) / Slider.slideRatio); }
Slider.pointValue = function(point) { return parseInt(point.style.left.substring(-2)); }
Slider.pointToSlide = function(pointValue) { return Math.round(pointValue / Slider.slideRatio + Slider.minVal); }
Slider.slideToPoint = function(slideValue) { return (slideValue - Slider.minVal) * Slider.slideRatio; }
Slider.setPoint = function(point, slideValue) { point.style.left = (slideValue - Slider.minVal) + "px"; }
Slider.start = function(e) {
	Slider.sliding = true;
	Slider.x = e.screenX;
	Slider.slider.addEventListener('mousemove', Slider.slide, false);
	Slider.slider.addEventListener('mouseup', Slider.stop, false);
	Slider.activept = e.target;
}
Slider.stop = function(e) {
	Slider.sliding = false;
	Slider.activept = null;
	Slider.slider.removeEventListener('mousemove', Slider.slide, false);
	Slider.slider.removeEventListener('mouseup', Slider.stop, false);
}
Slider.slide = function(e) {
	if(Slider.sliding) {
		var newPt = Slider.pointValue(Slider.activept)+e.screenX-Slider.x;
		// verify
		if (newPt < 0) { newPt = 0; }
		if (newPt > Slider.length) { newPt = Slider.length; }
		if (Slider.activept == Slider.ptrL && Slider.pointToSlide(newPt) >= Slider.sliderValue(Slider.ptrR)) {
			newPt = Slider.slideToPoint(Slider.pointToSlide(newPt) - 1);
		}
		if (Slider.activept == Slider.ptrR && Slider.pointToSlide(newPt) <= Slider.sliderValue(Slider.ptrL)) {
			newPt = Slider.slideToPoint(Slider.pointToSlide(newPt) + 1);
		}

		// do cover
		Slider.activept.style.left = newPt+"px";
		if (Slider.activept == Slider.ptrL) {
			Slider.cover.style.left = newPt+"px";
		} 
		Slider.cover.style.width = Slider.pointValue(Slider.ptrR) - Slider.pointValue(Slider.ptrL)+"px";
		Slider.$(Slider.activept.id + "_display").value = Slider.sliderValue(Slider.activept);
		Slider.x = e.screenX; // update current position
	}
}
