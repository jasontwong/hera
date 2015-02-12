app = angular.module 'dashboard.feedbacks', [
  'ngTable'
  'dashboard.filters'
]

app.controller 'FeedbackController', [
  'dataFactory'
  '$http'
  '$scope'
  '$filter'
  '$modal'
  'ngTableParams'
  (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
    feedback = this
    feedback.hideFilter = true
    feedback.feedbacks = []
    # {{{ feedback.delete = (key) ->
    feedback.delete = (key) ->
      feedback.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      feedback
        .modal
        .result
        .then ->
          feedback.refreshData()
      feedback
        .modal
        .opened
        .then ->
          $http
            .delete '/feedback/' + key
            .success ->
              feedback
                .modal
                .close()
              return
            .error ->
              feedback
                .modal
                .close()
              return
      return

    # }}}
    # {{{ feedback.send = (key) ->
    feedback.send = (key) ->
      feedback.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      feedback
        .modal
        .result
        .then ->
          feedback.refreshData()
      feedback
        .modal
        .opened
        .then ->
          $http
            .post '/feedback/' + key
            .success ->
              feedback
                .modal
                .close()
              return
            .error ->
              feedback
                .modal
                .close()
              return
      return

    # }}}
    # {{{ feedback.show = (survey) ->
    feedback.show = (survey) ->
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
    # {{{ feedback.refreshData = (force) ->
    feedback.refreshData = (force) ->
      feedback.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      feedback
        .modal
        .opened
        .then ->
          dataFactory
            .getFeedbacks force
            .success (data) ->
              feedback.feedbacks = data
              $scope.refresh++
              feedback
                .modal
                .close()
              return
            .error () ->
              feedback
                .modal
                .close()
              return
      return

    # }}}
    # {{{ $scope.$watch "refresh", () ->
    $scope.$watch "refresh", () ->
      $scope
        .tableParams
        .reload()
      return

    # }}}
    # {{{ $scope.tableParams = new ngTableParams(
    $scope.tableParams = new ngTableParams(
        page: 1
        count: 10
      ,
        total: feedback.feedbacks.length
        getData: ($defer, params) ->
          data = feedback.feedbacks
          data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
          params.total data.length
          $defer
            .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
          return
    )

    # }}}
    $scope.refresh = 0
    feedback.refreshData()
    return
]
