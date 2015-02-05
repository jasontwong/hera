app = angular.module 'dashboard.members', [
  'ngTable'
  'dashboard.filters'
]

app
  .controller 'MemberController', [
    '$http'
    '$scope'
    '$filter'
    '$modal'
    'ngTableParams'
    ($http, $scope, $filter, $modal, ngTableParams) ->
      member = this
      member.hideFilter = true
      member.members = []
      member.filteredMembers = []
      member.filterMembers = () ->
        data = member.members
        data = $filter('filter')(data, $scope.filters)
        data = $filter('filter')(data, $scope.exactFilters, member.processExactFilters)
        member.filteredMembers = data
      member.refreshData = () ->
        member.modal = $modal.open
          templateUrl: 'loadingModal'
          keyboard: false
          backdrop: 'static'
        $http
          .get '/data/members.json'
          .success (data) ->
            member.members = data
            $scope.refresh++
            member
              .modal
              .close()
            return
      member.processExactFilters = (actual, expected) ->
        return true if expected == "" || expected == null
        return false if actual == undefined
        return actual.toLowerCase() == expected
      $scope.refresh = 0
      $scope.exactFilters =
        attributes:
          gender: ''
      $scope.filters =
        active: ''
        email: ''
      $scope.$watch "refresh", () ->
        member.filterMembers()
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
      member.refreshData()
      return
  ]
