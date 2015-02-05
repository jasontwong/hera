app = angular.module 'dashboard.surveys', [
  'ngTable'
  'ui.bootstrap'
  'ui.unique'
  'dashboard.filters'
]

app
  .controller 'SurveyController', [
    '$http'
    '$scope'
    '$filter'
    '$modal'
    'ngTableParams'
    ($http, $scope, $filter, $modal, ngTableParams) ->
      survey = this
      survey.hideFilter = true
      survey.surveys = []
      survey.filteredSurveys = []
      survey.filterSurveys = () ->
        data = survey.surveys
        data = $filter('orderBy')(data, [ '-created_at' ])
        data = $filter('filter')(data, $scope.filters.normal)
        data = $filter('filter')(data, survey.processFilters.visited)
        data = $filter('filter')(data, survey.processFilters.completed)
        data = $filter('unique')(data, $scope.filters.unique) if $scope.filters.unique != ''
        survey.filteredSurveys = data
        return
      survey.npsClass = (score) ->
        return "" if isNaN score
        return "success" if score >= 7
        return "danger" if score <= 3
        "warning"
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
      survey.refreshData = () ->
        survey.modal = $modal.open
          templateUrl: 'loading-modal'
          keyboard: false
          backdrop: 'static'
        $http
          .get '/data/surveys.json'
          .success (data) ->
            survey.surveys = data
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
      $scope.refresh = 0
      $scope.filters =
        normal:
          completed: 'true'
          store:
            name: ''
          member:
            email: ''
        date:
          completed:
            start: ''
            end: ''
          visited:
            start: ''
            end: ''
        unique: ''
      $scope.$watch "refresh", () ->
        survey.filterSurveys()
        $scope
          .tableParams
          .reload()
        return
      $scope.$watch "filters", () ->
        $scope.refresh++
        return
      , true
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
      survey.refreshData()
      return
  ]
