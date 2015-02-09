app = angular.module 'dashboard.surveys', [
  'ngTable'
  'ui.bootstrap'
  'dashboard.filters'
]

app
  .controller 'SurveyController', [
    'stormData'
    '$http'
    '$scope'
    '$filter'
    '$modal'
    'ngTableParams'
    (stormData, $http, $scope, $filter, $modal, ngTableParams) ->
      survey = this
      survey.hideFilter = true
      survey.surveys = stormData.surveys
      survey.filteredSurveys = stormData.surveys
      # {{{ survey.filterSurveys = () ->
      survey.filterSurveys = () ->
        data = survey.surveys
        data = $filter('filter')(data, $scope.filters.normal)
        data = $filter('filter')(data, survey.processFilters.visited) if $scope.filters.date.visited.start != '' or $scope.filters.date.visited.end != ''
        survey.filteredSurveys = data
        return

      # }}}
      # {{{ survey.show = (survey) ->
      survey.show = (survey) ->
        $modal.open
          templateUrl: 'survey-modal'
          controller: ($scope, $modalInstance, survey) ->
            $scope.survey = survey
            $scope.cancel = () ->
              $modalInstance.dismiss('cancel')
            return
          resolve:
            survey: () ->
              survey
        return

      # }}}
      # {{{ survey.refreshData = () ->
      survey.refreshData = () ->
        survey.modal = $modal.open
          templateUrl: 'loading-modal'
          keyboard: false
          backdrop: 'static'
        $http
          .get '/data/surveys.json'
          .success (data) ->
            survey.surveys = data
            stormData.surveys = data
            $scope.refresh++
            survey
              .modal
              .close()
            return
          .error () ->
            survey
              .modal
              .close()
            return
        return

      # }}}
      # {{{ survey.processFilters =
      survey.processFilters =
        date: (dates, check_time) ->
          start = new Date(dates.start).getTime()
          end = new Date(dates.end).getTime()
          valid = true
          valid = check_time >= start if valid and !isNaN start
          valid = check_time <= end if valid and !isNaN end
          valid
        visited: (value, index) ->
          survey.processFilters.date $scope.filters.date.visited, value.created_at
        completed: (value, index) ->
          survey.processFilters.date $scope.filters.date.completed, value.completed_at

      # }}}
      # {{{ $scope.calendars =
      $scope.calendars =
        config:
          showWeeks: false
        visited:
          end:
            open: false
            toggle: ($event) ->
              $event.preventDefault()
              $event.stopPropagation()
              $scope.calendars.visited.end.open = !$scope.calendars.visited.end.open
              return
          start:
            open: false
            toggle: ($event) ->
              $event.preventDefault()
              $event.stopPropagation()
              $scope.calendars.visited.start.open = !$scope.calendars.visited.start.open
              return

      # }}}
      # {{{ $scope.filters =
      $scope.filters =
        normal:
          completed: 'true'
          store:
            name: ''
          member:
            email: ''
        date:
          visited:
            start: ''
            end: ''

      # }}}
      # {{{ $scope.$watch "refresh", () ->
      $scope.$watch "refresh", () ->
        survey.filterSurveys()
        $scope
          .tableParams
          .reload()
        return

      # }}}
      # {{{ $scope.$watch "filters", () ->
      $scope.$watch "filters", () ->
        $scope.refresh++
        return
      , true

      # }}}
      # {{{ $scope.tableParams = new ngTableParams(
      $scope.tableParams = new ngTableParams(
          page: 1
          count: 10
          sorting:
            created_at: 'desc'
        ,
          total: survey.filteredSurveys.length
          getData: ($defer, params) ->
            data = survey.filteredSurveys
            data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
            params.total data.length
            $defer
              .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
            return
      )

      # }}}
      $scope.refresh = 0
      survey.refreshData() if stormData.surveys.length == 0
      return
  ]
