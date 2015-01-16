(function($) {
  $(function() {
    // Get context with jQuery - using jQuery's .get() method.
    var stores_charts = $(".stores-chart"),
      stats = [
        stores_charts.eq(0).data('stats'),
      ];
    new Chart(stores_charts.get(0).getContext("2d"))
      .Pie([{
          value: stats[0].active,
          color:"#46BFBD",
          highlight: "#5AD3D0",
          label: "Active"
        },{
          value: stats[0].total - stats[0].active,
          color:"#FDB45C",
          highlight: "#FFC870",
          label: "Inactive"
        }].sort(function(a, b) {
          return b.value - a.value;
        }));
    d3.json('/data/stores.json', function(err, data) {
      if (!err) {
        var map = L.map('stores-engagement-map').setView([41.881320, -87.630440], 13),
          markerColor = d3.interpolateRgb('#ffffff','#ff0000'),
          maxSurveys = 20,
          store;

        L.tileLayer('http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png', {
          attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
          subdomains: 'abcd',
          minZoom: 0,
          maxZoom: 20
        }).addTo(map);

        for(var i = 0, l = data.length; i < l; i++) {
          store = data[i];
          new L.Circle(L.latLng(store.lat, store.lng), 30.5, {
            color: markerColor(store.surveys/maxSurveys),
            fillOpacity: 1
          }).addTo(map);
        }
      }
    });
  });
}(jQuery));
