app = angular.module 'dashboard.checkins', [
  'ngTable'
  'ui.bootstrap'
  'dashboard.filters'
]

app.controller 'CheckinController', [
  'dataFactory'
  '$http'
  '$scope'
  '$filter'
  '$modal'
  'ngTableParams'
  (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
    checkin = this
    checkin.hideFilter = true
    checkin.checkins = []
    checkin.filteredCheckins = []
    # {{{ checkin.filterCheckins = () ->
    checkin.filterCheckins = () ->
      data = checkin.checkins
      data = $filter('filter')(data, $scope.filters.normal)
      data = $filter('filter')(data, checkin.processFilters.visited) if $scope.filters.date.visited.start? or $scope.filters.date.visited.end?
      checkin.filteredCheckins = data
      return

    # }}}
    # {{{ checkin.show = (checkin) ->
    checkin.show = (checkin) ->
      $modal.open
        templateUrl: 'checkin-modal'
        controller: ($scope, $modalInstance, checkin) ->
          $scope.checkin = checkin
          $scope.cancel = () ->
            $modalInstance.dismiss('cancel')
          return
        resolve:
          checkin: () ->
            checkin
      return

    # }}}
    # {{{ checkin.refreshData = (force) ->
    checkin.refreshData = (force) ->
      checkin.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      closeModal = () ->
        checkin
          .modal
          .close()
        return
      checkin
        .modal
        .opened
        .then ->
          dataFactory
            .getCheckins force
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
                      checkin.checkins = data
                      $scope.refresh++
                      closeModal()
                      return
                    .error closeModal
                .error closeModal
            .error closeModal
      return

    # }}}
    # {{{ checkin.processFilters =
    checkin.processFilters =
      date: (dates, check_time) ->
        start = if dates.start? then new Date(dates.start).getTime() else NaN
        end = if dates.end? then new Date(dates.end).getTime() else NaN
        valid = true
        valid = check_time >= start if valid and not isNaN start
        valid = check_time <= end if valid and not isNaN end
        valid
      visited: (value, index) ->
        checkin.processFilters.date $scope.filters.date.visited, value.created_at
      completed: (value, index) ->
        checkin.processFilters.date $scope.filters.date.completed, value.completed_at

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
      checkin.filterCheckins()
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
        total: checkin.filteredCheckins.length
        getData: ($defer, params) ->
          data = checkin.filteredCheckins
          data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
          params.total data.length
          $defer
            .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
          return
    )

    # }}}
    $scope.refresh = 0
    checkin.refreshData()
    return
]
