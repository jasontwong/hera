app = angular.module 'dashboard.emails', [
  'ngTable'
  'dashboard.filters'
]

app.controller 'EmailsController', [
  'dataFactory'
  '$http'
  '$scope'
  '$filter'
  '$modal'
  'ngTableParams'
  (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
    emails = this
    emails.hideFilter = true
    emails.emails = []
    # {{{ emails.delete = (key) ->
    emails.delete = (key) ->
      emails.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      emails
        .modal
        .result
        .then ->
          emails.refreshData()
      emails
        .modal
        .opened
        .then ->
          $http
            .delete '/emails/' + key
            .success ->
              emails
                .modal
                .close()
              return
            .error ->
              emails
                .modal
                .close()
              return
      return

    # }}}
    # {{{ emails.send = (key, data = {}) ->
    emails.send = (key, data = {}) ->
      emails.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      emails
        .modal
        .result
        .then ->
          emails.refreshData()
      emails
        .modal
        .opened
        .then ->
          $http
            .post('/emails/' + key, data)
            .success ->
              emails
                .modal
                .close()
              return
            .error ->
              emails
                .modal
                .close()
              return
      return

    # }}}
    # {{{ emails.showTest = (survey_key) ->
    emails.showTest = (survey_key) ->
      $modal.open
        templateUrl: 'email-modal'
        controller: ($scope, $modalInstance, survey_key) ->
          $scope.data =
            email: ""
          $scope.survey_key = survey_key
          $scope.cancel = () ->
            $modalInstance.dismiss('cancel')
          $scope.send = (key, test) ->
            $scope.data.test = test
            emails.send(key, $scope.data)
            $modalInstance.dismiss('cancel')
          return
        resolve:
          survey_key: ->
            survey_key
      return

    # }}}
    # {{{ emails.show = (survey) ->
    emails.show = (survey) ->
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
    # {{{ emails.refreshData = (force) ->
    emails.refreshData = (force) ->
      emails.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      emails
        .modal
        .opened
        .then ->
          dataFactory
            .getEmails force
            .success (data) ->
              for obj in data
                for ans in obj.survey.answers
                  if ans.type == 'switch' and !isNaN(parseFloat(ans.answer))
                    ans.answer = if ans.answer == "1" then "YES" else "NO"
              emails.emails = data
              $scope.refresh++
              emails
                .modal
                .close()
              return
            .error () ->
              emails
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
        total: emails.emails.length
        getData: ($defer, params) ->
          data = emails.emails
          data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
          params.total data.length
          $defer
            .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
          return
    )

    # }}}
    $scope.refresh = 0
    emails.refreshData()
    return
]
