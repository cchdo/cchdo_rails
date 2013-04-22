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
    var latlngs = $.map($('#latlons').val().split("\n"), function(x) {
      var latlng = $.map(x.split(', '), function(x) {return parseInt(x, 10);});
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
           {label: 'Begin Date', type: 'date'},
           {label: 'data', type: 'string'}],
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
  _dialogs: null,
  i_to_d: null
};
CM.Info.prototype.table_rows = function() { return $('tr', this.jdom); }
CM.Info.prototype.dialogs = function() { 
  if (this._dialogs === null) {
    this._dialogs = $('<div id="data-formats-dialogs"></div>');
    this._dialogs.appendTo('body');
  }
  return this._dialogs;
}
CM.Info.prototype.setJdom = function(jdom) {
  if (this.jdom) {
    this.jdom.empty();
    delete this.info_table;
  }
  this.jdom = jdom;
  this.info_table = new google.visualization.Table(this.jdom[0]);

  var CMI = this;
  this.jdom.delegate('tr', 'mouseenter', function() {
    CM.results.dim(CMI.get_id(this), true);
    return false;
  }).delegate('tr', 'mouseleave', function() {
    CM.results.darken(CMI.get_id(this), true);
    return false;
  }).delegate('tr', 'click', function() {
    CM.results.lighten(CMI.get_id(this), true);
  });
  google.visualization.events.addListener(this.info_table, 'sort', function(event) {
    CMI.sync_sortorder(event);
  });

  this.jdom.delegate('button[infodata-id]', 'click', function() {
    var button = $(this);
    var iid = button.attr('infodata-id');
    $('#' + iid).dialog({
      width: 350,
      position: {my: 'right', at: 'left', of: button},
    });
    return false;
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
  var dataid = info.id;
  var datadiv = $('<div>' + info.data + '</div>').
    addClass('data-formats').
    css('position', 'relative').
    attr('title', info.expocode).
    attr('id', 'infodata' + info.cruise_id).
    appendTo(this.dialogs());
  var databutton = '<button class="datacart-blank" infodata-id="infodata' +
    info.cruise_id +'" title="Add/remove data">' +
    '<div class="datacart-icon"></div></button>';

  var data_row = this.info_data_table.addRow(
    [info.line, info.expocode, info.ship, info.country, info.pi,
     info.date_begin, databutton]);
  if (notrack) {
    for (var i=0; i<this.info_data_table.getNumberOfColumns(); i++) {
      this.info_data_table.setProperty(data_row, i, 'style', 'background-color: #ffdddd;');
    }
  }
  return data_row;
};
CM.Info.prototype.remove = function(id, delay) {
  this.info_data_table.removeRow(id);
  if (!delay) {
    this.redraw();
  }
};
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
  var close_button = $('<div id="pop_button">Pop in results <img src="images/map_search/popin.png" title="Popin" alt="Popin" /></div>')
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
function parseYYYYmmdd(s) {
  try {
    return new Date(Number(s.slice(0, 4)), Number(s.slice(5, 7)), Number(s.slice(8, 10)));
  } catch (e) {
    return null;
  }
}
CM.results = {
  lit: -1,
  info_entry: {},
  entry_info: {},
  add: function(expocode, track) {
    /* Fetch more information for the cruise record display */
    track = $.map(track, function(x) {return new google.maps.LatLng(x[0], x[1]);});
    $.ajax({type: 'GET', url: '/map_search/info?expocode='+expocode, dataType: 'json',
      beforeSend: function() {CM.state('Fetching '+expocode);},
      success: function(response) {
        try {
          CM.state('Received '+expocode);
          var CME = CM.entries;
          var info = response;
          var cruise_link = '<a href="/cruise/'+expocode+'">'+expocode+'</a>';
          if (info) {
            info.expocode = cruise_link;
            info.date_begin = parseYYYYmmdd(info.date_begin);
            info.date_end = parseYYYYmmdd(info.date_end);
          } else {
            info = {'expocode': cruise_link, 'line': null, 'ship': null,
                    'country': null, 'pi': null, 'date_begin': null};
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

          $(CM.results).trigger('added');

          CM.state('');
        } catch(e) {
          console.log('Error handling received cruise information:', e);
        }
      }
    });
  },
  clear: function() {
    for (var info_id in this.info_entry) {
      this.remove(parseInt(info_id, 10), true, true);
    }
    CM.info.redraw();
  },
  remove: function(id, is_info_id, delay) {
    if (!is_info_id) { id = this.entry_info[id]; }
    var entry_id = this.info_entry[id];
    CM.entries.remove(entry_id);
    CM.info.remove(id, delay);
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
  if ($.inArray(tool_button.id.replace('_button', ''),
                this.need_granularity)) {
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
  var num_ids = 0;
  for (var expocode in cruise_tracks) {
    check = expocode;
    num_ids += 1;
    CM.results.add(expocode, cruise_tracks[expocode]);
  }
  if (check === undefined) {
    CM.state('No cruises found');
    this.results.clear();
  } else {
    CM.pane.activate();
    CM.pane.unshade();
  }
  var added = 0;
  CM.state('Adding info');
  $(CM.results).bind('added', function () {
    added += 1;
    if (added == num_ids) {
      CM.state('');
      CM.info.redraw();
      $(this).unbind();
    }
  });
};
CM.remote_submit = function() { $('form[name=tool_details]').submit(); };
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

  $('form[name=tool_details]').submit(function() {
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
  $('form[name=tool_details] :submit').click(function() {
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
