(function($) {
  $(function() {
    // Get context with jQuery - using jQuery's .get() method.
    var members_chart = $("#members-chart"),
      stats = members_chart.data('stats');
    new Chart(members_chart.get(0).getContext("2d"))
      .PolarArea([{
          value: stats.active,
          color:"#46BFBD",
          highlight: "#5AD3D1",
          label: "Active"
        },{
          value: stats.visits,
          color:"#FDB45C",
          highlight: "#FFC870",
          label: "Visits"
        },{
          value: stats.redeemed,
          color:"#949FB1",
          highlight: "#A8B3C5",
          label: "Redeemed"
        }].sort(function(a, b) {
          return b.value - a.value;
        }));
  });
}(jQuery));
