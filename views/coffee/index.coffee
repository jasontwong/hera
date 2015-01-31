app = angular.module 'dashboard.index', [
]

app.directive 'd3Bars', [
  '$window'
  '$timeout'
  ($window, $timeout) ->
    restrict: 'EA'
    scope: {
      data: '=chartData'
    }
    controller: ($scope) ->
      $scope.data= [
          name: 'Greg'
          score: 98
        ,
          name: 'Ari'
          score: 96
        ,
          name: 'Q'
          score: 75
        ,
          name: 'Loser'
          score: 48
      ]
    link: (scope, ele, attrs) ->
      margin = parseInt(attrs.margin) || 20
      barHeight = parseInt(attrs.barHeight) || 20
      barPadding = parseInt(attrs.barPadding) || 5
      svg = d3.select ele[0]
        .append 'svg'
        .style 'width', '100%'

      # Browser onresize event
      window.onresize = () ->
        scope.$apply()
        return

      # hard-code data
      # scope.data = [
      #     name: 'Greg'
      #     score: 98
      #   ,
      #     name: 'Ari'
      #     score: 96
      #   ,
      #     name: 'Q'
      #     score: 75
      #   ,
      #     name: 'Loser'
      #     score: 48
      # ]

      # watch for resize event
      scope.$watch () ->
        angular.element($window)[0].innerWidth
      , () ->
        scope.render scope.data
        return

      scope.render = (data) ->
        svg
          .selectAll '*'
          .remove()
        return if !data
        clearTimeout renderTimeout if renderTimeout

        renderTimeout = $timeout () ->
          width = d3.select ele[0]
            .node()
            .offsetWidth - margin
          height = scope
            .data
            .length * (barHeight + barPadding)
          color = d3
            .scale
            .category20()
          xScale = d3
            .scale
            .linear()
            .domain [
              0
              d3.max data, (d) ->
                d.score
            ]
            .range [
              0
              width
            ]

          svg
            .attr 'height', height

          svg
            .selectAll 'rect'
            .data data
            .enter()
            .append 'rect'
            .attr 'height', barHeight
            .attr 'width', 140
            .attr 'x', Math.round margin/2
            .attr 'y', (d, i) ->
              i * (barHeight + barPadding)
            .attr 'fill', (d) ->
              color d.score
            .transition()
            .duration 1000
            .attr 'width', (d) ->
              xScale d.score
          svg
            .selectAll 'text'
            .data data
            .enter()
            .append 'text'
            .attr 'fill', '#fff'
            .attr 'y', (d, i) ->
              i * (barHeight + barPadding) + 15
            .attr 'x', '15'
            .text (d) ->
              d.name + " (scored: " + d.score + ')'
          return
        , 200
        return
]
