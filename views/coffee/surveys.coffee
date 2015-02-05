app = angular.module 'dashboard.surveys', [
  'ngTable'
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
        data = $filter('filter')(data, $scope.filters)
        data = $filter('filter')(data, $scope.exactFilters, survey.processExactFilters)
        survey.filteredSurveys = data
      survey.refreshData = () ->
        survey.modal = $modal.open
          templateUrl: 'loadingModal'
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
      survey.processExactFilters = (actual, expected) ->
        return true if expected == "" || expected == null
        return false if actual == undefined
        return actual.toLowerCase() == expected
      $scope.refresh = 0
      $scope.exactFilters = {}
      $scope.filters =
        completed: 'true'
        store:
          name: ''
        member:
          email: ''
      $scope.$watch "refresh", () ->
        survey.filterSurveys()
        $scope
          .tableParams
          .reload()
        return
      $scope.$watch "filters", () ->
        $scope
          .tableParams
          .filter($scope.filters)
        $scope.refresh++
        return
      , true
      $scope.$watch "exactFilters", () ->
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
