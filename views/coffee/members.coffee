app = angular.module 'dashboard.members', [
  'ngTable'
  'dashboard.filters'
]

app.controller 'MemberController', [
  'dataFactory'
  '$http'
  '$scope'
  '$filter'
  '$modal'
  'ngTableParams'
  (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
    member = this
    member.hideFilter = true
    member.members = []
    member.filteredMembers = []
    # {{{ member.filterMembers = () ->
    member.filterMembers = () ->
      data = member.members
      data = $filter('filter')(data, $scope.filters.normal)
      data = $filter('filter')(data, $scope.filters.exact, member.processFilters.exact)
      data = $filter('filter')(data, member.processFilters.age) if angular.isNumber($scope.filters.age.start) or angular.isNumber $scope.filters.age.end
      data = $filter('filter')(data, member.processFilters.surveys) if angular.isNumber($scope.filters.surveys.min) or angular.isNumber $scope.filters.surveys.max
      member.filteredMembers = data

    # }}}
    # {{{ member.refreshData = (force) ->
    member.refreshData = (force) ->
      member.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      member
        .modal
        .opened
        .then ->
          dataFactory
            .getMembers force
            .success (data) ->
              obj.attributes.age = $filter('age')(obj.attributes.birthday) for obj in data when obj.attributes.birthday isnt undefined
              member.members = data
              $scope.refresh++
              member
                .modal
                .close()
              return
            .error () ->
              member
                .modal
                .close()
              return
      return

    # }}}
    # {{{ member.processFilters =
    member.processFilters =
      exact: (actual, expected) ->
        return true if not expected? or expected == ""
        return false unless actual?
        actual.toLowerCase() == expected
      age: (value, index) ->
        start = parseInt $scope.filters.age.start, 10
        end = parseInt $scope.filters.age.end, 10
        valid = true
        valid = value.attributes.age >= start if valid and !isNaN start
        valid = value.attributes.age <= end if valid and !isNaN end
        valid
      surveys: (value, index) ->
        min = parseInt $scope.filters.surveys.min, 10
        max = parseInt $scope.filters.surveys.max, 10
        valid = true
        valid = value.stats.surveys.submitted >= min if valid and !isNaN min
        valid = value.stats.surveys.submitted <= max if valid and !isNaN max
        valid

    # }}}
    # {{{ member.showStats = () ->
    member.showStats = () ->
      $modal.open
        templateUrl: 'member-stats-modal'
        controller: ($scope, $modalInstance, members) ->
          $scope.stats = [
              name: 'Average surveys completed'
              value: do ->
                avg = 0
                avg += obj.stats.surveys.submitted for obj in members when angular.isNumber obj.stats.surveys.submitted
                Math.round(avg / members.length * 100) / 100
            ,
              name: 'Average age'
              value: do ->
                avg = 0
                avg += obj.attributes.age for obj in members when angular.isNumber obj.attributes.age
                Math.round(avg / members.length * 100) / 100
            ,
              name: 'Rewards redeemed'
              value: do ->
                total = 0
                total += obj.stats.rewards.redeemed for obj in members when angular.isNumber obj.stats.rewards.redeemed
                total
          ]
          $scope.cancel = () ->
            $modalInstance.dismiss('cancel')
          return
        resolve:
          members: () ->
            member.filteredMembers
      return
    # }}}
    # {{{ $scope.filters =
    $scope.filters =
      normal:
        active: ''
        email: ''
      exact:
        attributes:
          gender: ''
      age:
        start: ''
        end: ''
      surveys:
        min: ''
        max: ''

    # }}}
    # {{{ $scope.$watch "refresh", () ->
    $scope.$watch "refresh", () ->
      member.filterMembers()
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
      ,
        total: member.filteredMembers.length
        getData: ($defer, params) ->
          data = member.filteredMembers
          data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
          params.total data.length
          $defer
            .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
          return
    )

    # }}}
    $scope.refresh = 0
    member.refreshData()
    return
]
