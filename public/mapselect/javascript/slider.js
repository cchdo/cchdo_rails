var minVal = 1980;
var maxVal = new Date().getFullYear();
var sliderLength = 200;
var slideRatio = sliderLength * 1. / (maxVal - minVal);

var x; // current event's x position
var activepoint;
var sliding = false; // flag
var currCoverWidth = sliderLength;
var ptrL, ptrR;

function initSlider () {
	slider = document.getElementById("slider");
	cover = document.getElementById("cover");
	cover.style.left = "0px";
	cover.style.width = sliderLength + "px";
	ptrL = document.getElementsByClassName("point_left")[0];
	ptrR = document.getElementsByClassName("point_right")[0];
}

function sliderValue (point) {
	return Math.round(minVal + pointValue(point) / slideRatio);
	//return minVal + pointValue(point) / slideRatio;
}

function pointValue (point) {
	return parseInt(point.style.left.substring(-2));
}

function pointValueToSlideValue (pointValue) {
	return Math.round(pointValue / slideRatio + minVal);
}

function slideValueToPointValue (slideValue) {
	return (slideValue - minVal) * slideRatio;
}

function startSlide (event) {
	sliding = true;
	x = event.screenX;
	document.onmousemove = slide;
	document.onmouseup = stopSlide;
	activepoint = event.target;
}

function setPoint (point, slideVal) {
	point.style.left = (slideVal - minVal) + "px";
}

function slide (event) {
	if (sliding) {
		var currleft = pointValue(activepoint);
		var delta = event.screenX - x;
		var newPoint = currleft + delta;
		// verify
		if (newPoint < 0) {
			newPoint = 0;
		}
		if (newPoint > sliderLength) {
			newPoint = sliderLength;
		}

		if (activepoint == ptrL && pointValueToSlideValue(newPoint) >= sliderValue(ptrR)) {
			newPoint = slideValueToPointValue(pointValueToSlideValue(newPoint) - 1);
		}

		if (activepoint == ptrR && pointValueToSlideValue(newPoint) <= sliderValue(ptrL)) {
			newPoint = slideValueToPointValue(pointValueToSlideValue(newPoint) + 1);
		}

		// do cover
		activepoint.style.left = newPoint + "px";
		if (activepoint == ptrL) {
			cover.style.left = newPoint + "px";
		} 
		cover.style.width = pointValue(ptrR) - pointValue(ptrL) + "px";

		document.getElementById(activepoint.id).innerHTML = sliderValue(activepoint);

		// update current position
		x = event.screenX;
	}
}
function stopSlide (event) {
	sliding = false;
	activepoint = null;
}
