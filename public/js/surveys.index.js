(function($) {
  $(function() {
    // Get context with jQuery - using jQuery's .get() method.
    var surveys_charts = $(".surveys-chart"),
      stats = [
        surveys_charts.eq(0).data('stats'),
      ],
      survey_modal = $('#survey-modal');
    survey_modal
      .on('show.bs.modal', function (event) {
        var el = $(this),
          row = $(event.relatedTarget),
          survey = row.data('survey'),
          store = row.data('store'),
          member = row.data('member'),
          body = $('.modal-body', el),
          survey_info = $('.survey-info .panel-body', body),
          survey_questions = $('.survey-questions .list-group', body);
        $('span', survey_info).empty();
        survey_questions.empty();
        for (var i in survey.answers) {
          if (survey.answers.hasOwnProperty(i)) {
            var ans = survey.answers[i],
              lg_item = $('<li class="list-group-item" />');
            lg_item.html('<span class="badge">' + ans.answer + '</span>' + ans.question);
            survey_questions.append(lg_item);
          }
        }
        $('.store span', survey_info).text(store.name);
        $('.email span', survey_info).text(member.email);
        $('.comments span', survey_info).text(survey.comments);
        $('.worth span', survey_info).text(survey.worth);
        $('.visited span', survey_info).text(survey.created_at_nice);
        $('.completed span', survey_info).text(survey.completed_at_nice);
        $('.nps_score span', survey_info).text(survey.nps_score);
      });
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
