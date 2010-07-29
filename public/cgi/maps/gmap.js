var request;
var queryString;   //will hold the POSTed data
var overlays = [];
var line_names = [];


function load() 
{
   if (GBrowserIsCompatible())
   {
      load_basin();
   }
}

/* This function is a quick way to get an object by id */
function $(id) { return document.getElementById(id); }



function load_basin(){
    var d=document;
    var lines = d.getElementById("Basin").innerHTML;
    lines = lines.replace(/^\s+/g,"");
    lines = lines.replace(/\s+$/g,"");
    lines = lines.replace(/\s/g,"%20");
    var url="http://cchdo.ucsd.edu/cgi/maps/ajax_gmt.cgi?basin="+lines;
   GDownloadUrl(url, function(data, responseCode) 
   { 
     // var xml = GXml.parse(data); 
if(responseCode == 200){
			if (typeof DOMParser != "undefined") {
		        // Mozilla, Firefox, and related browsers
		       //var xml = (new DOMParser( )).parseFromString(text, "application/xml");
		      	      var chopped_data = data.substring(124,data.length)
				var xml = GXml.parse(data); 
		    }
		    else if (typeof ActiveXObject != "undefined") {
		        // Internet Explorer.
		       var xml = new ActiveXObject("MSXML2.DOMDocument");
		       // var xml = XML.newDocument( );  // Create an empty document
		        //xml.loadXML(data);            // Parse text into it
		      var index = data.indexOf("<html xml")
		      var chopped_data = data.substring(index-1,data.length)
		      xml = GXml.parse(chopped_data); 
		    }
      //var xml = data;//request.responseXML;
      var root = xml.documentElement;
      //var lat = xml.getElementsByTagName("lon")[0].innerHTML;
      var lat = xml.getElementsByTagName("lat")[0].firstChild.nodeValue;
      //var lon = xml.getElementsByTagName("lon")[0].innerHTML;
      var lon = xml.getElementsByTagName("lon")[0].firstChild.nodeValue;
//var zoom = xml.getElementsByTagName("zoom")[0].innerHTML;
      var zoom = xml.getElementsByTagName("zoom")[0].firstChild.nodeValue;
		var coord_list = xml.getElementsByTagName("coordinates");
      zoom = parseInt(zoom);

      if(coord_list.length > 0)
      {
         var bounding_box = [];
    		var map = new GMap2(document.getElementById("map"));
			map.addControl(new GSmallZoomControl());
			map.addControl(new GMapTypeControl());
         map.setCenter(new GLatLng(lat,lon), zoom);
         var labels = [];
         for(var ctr =0; ctr < coord_list.length;ctr++)
         {
                var points = [];
             var cur_children = coord_list[ctr].childNodes;
             for( var coord_ctr = 0; coord_ctr< cur_children.length; coord_ctr++)
             {
                   var cur_label = cur_children[coord_ctr].getElementsByTagName("lineno")[0].firstChild.nodeValue;
     					 var cur_expo = cur_children[coord_ctr].getElementsByTagName("expo")[0].firstChild.nodeValue;
                   var cur_lat = cur_children[coord_ctr].getElementsByTagName("lat")[0].firstChild.nodeValue;
                   var cur_lon = cur_children[coord_ctr].getElementsByTagName("lon")[0].firstChild.nodeValue;
             address = cur_lat+"    "+cur_lon;          
    points.push(new GLatLng(cur_lat,cur_lon));      
}
             labels.push(cur_label);
             var line = new GPolyline(points,'#ff0000',3);
             overlays.push(line);
             line_names.push(cur_label);
                map.addOverlay(line);

             var address = "ExpoCode="+cur_expo;

             map.addOverlay(createMarker(points[1],address,cur_label,map));
         }

      }
}
   });
}
// Creates a marker at the given point with the given number label
function createMarker(point, address,line,map) {
  var marker = new GMarker(point);
  var link = $(line);
  var index;
  var points = [];

  //$("message").innerHTML+="<h1>"+link.innerHTML+"</h1>";
  GEvent.addListener(marker, "click", function() {
    marker.openInfoWindowHtml("<a href=http://cchdo.ucsd.edu/data_access?"+address+">"+line+"</a>");
  });
  GEvent.addDomListener(link, "mouseover", function() {

	   for(var ctr = 0; ctr< line_names.length; ctr++)
	   {
		   if(line_names[ctr] == line){index = ctr;}
   	}
	   var temp_line = overlays[index];
	   map.removeOverlay(temp_line);
	   for(var ctr=0; ctr< temp_line.getVertexCount(); ctr++)
	   {
		   points.push(temp_line.getVertex(ctr));
	   }
	   var new_line = new GPolyline(points,'#00ff00',3);
	   map.addOverlay(new_line);
    marker.openInfoWindowHtml("<a href=http://cchdo.ucsd.edu/data_access?"+address+">"+line+"</a>");
	   //map.addOverlay(new_line);
  });
  GEvent.addDomListener(link,"mouseout",function(){
	   for(var ctr = 0; ctr< line_names.length; ctr++)
	   {
		   if(line_names[ctr] == line){index = ctr;}
  	}
	   var temp_line = overlays[index];
	   map.removeOverlay(temp_line);
	   for(var ctr=0; ctr< temp_line.getVertexCount(); ctr++)
	   {
		   points.push(temp_line.getVertex(ctr));
	   }
	   var new_line = new GPolyline(points,'#ff0000',3);
	   map.addOverlay(new_line);
	
})
  return marker;
}

