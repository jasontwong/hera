app = angular.module 'dashboard.surveys', [
  'ngTable'
  'ui.bootstrap'
  'dashboard.filters'
]

app.controller 'SurveyController', [
  'dataFactory'
  '$http'
  '$scope'
  '$filter'
  '$modal'
  'ngTableParams'
  (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
    survey = this
    survey.hideFilter = true
    survey.surveys = []
    survey.filteredSurveys = []
    # {{{ survey.filterSurveys = () ->
    survey.filterSurveys = () ->
      data = survey.surveys
      $scope.filters.normal.first_time = '' if $scope.filters.normal.first_time == false
      data = $filter('filter')(data, $scope.filters.normal)
      data = $filter('filter')(data, survey.processFilters.visited) if $scope.filters.date.visited.start? or $scope.filters.date.visited.end?
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
    # {{{ survey.refreshData = (force) ->
    survey.refreshData = (force) ->
      survey.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      closeModal = () ->
        survey
          .modal
          .close()
        return
      survey
        .modal
        .opened
        .then ->
          dataFactory
            .getSurveys force
            .success (data) ->
              dataFactory
                .getMembers force
                .success (members) ->
                  dataFactory
                    .getStores force
                    .success (stores) ->
                      storesFound = {}
                      membersFound = {}
                      for obj in data
                        member = membersFound[obj.member_key] || $filter('findBy')(members, 'key', obj.member_key)
                        if member?
                          membersFound[obj.member_key] = member
                          obj.member = member
                        store = storesFound[obj.store_key] || $filter('findBy')(stores, 'key', obj.store_key)
                        if store?
                          storesFound[obj.store_key] = store
                          obj.store = store
                        for ans in obj.answers
                          if ans.type == 'switch' and !isNaN(parseFloat(ans.answer))
                            ans.answer = if ans.answer == "1" then "YES" else "NO"
                      survey.surveys = data
                      $scope.refresh++
                      closeModal()
                      return
                    .error closeModal
                .error closeModal
            .error closeModal
      return

    # }}}
    # {{{ survey.processFilters =
    survey.processFilters =
      date: (dates, check_time) ->
        start = if dates.start? then new Date(dates.start) else NaN
        end = if dates.end? then new Date(dates.end) else NaN
        valid = true
        if valid and not isNaN start
          start.setHours(0, 0, 0, 0)
          valid = check_time >= +start
        if valid and not isNaN end
          end.setHours(23, 59, 59, 999)
          valid = check_time <= +end
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
        first_time: ''
        completed: 'true'
        store:
          name: ''
        member:
          email: ''
      date:
        visited:
          start: null
          end: null

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
    survey.refreshData()
    return
]
