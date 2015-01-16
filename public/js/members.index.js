(function($) {
  $(function() {
    // Get context with jQuery - using jQuery's .get() method.
    var members_charts = $(".members-chart"),
      stats = [
        members_charts.eq(0).data('stats'),
      ];
    new Chart(members_charts.get(0).getContext("2d"))
      .PolarArea([{
          value: stats[0].active,
          color:"#46BFBD",
          highlight: "#5AD3D1",
          label: "Active"
        },{
          value: stats[0].visits,
          color:"#FDB45C",
          highlight: "#FFC870",
          label: "Visits"
        },{
          value: stats[0].redeemed,
          color:"#949FB1",
          highlight: "#A8B3C5",
          label: "Redeemed"
        }].sort(function(a, b) {
          return b.value - a.value;
        }));
  });
}(jQuery));
