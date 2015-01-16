(function($) {
  $(function() {
    // Get context with jQuery - using jQuery's .get() method.
    var surveys_charts = $(".surveys-chart"),
      stats = [
        surveys_charts.eq(0).data('stats'),
      ];
    new Chart(surveys_charts.get(0).getContext("2d"))
      .Pie([{
          value: stats[0].completed,
          color:"#46BFBD",
          highlight: "#5AD3D0",
          label: "Complete"
        },{
          value: stats[0].total - stats[0].completed,
          color:"#FDB45C",
          highlight: "#FFC870",
          label: "Incomplete"
        }].sort(function(a, b) {
          return b.value - a.value;
        }));
  });
}(jQuery));
