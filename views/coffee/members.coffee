app = angular.module 'dashboard.members', [
  'ngTable'
  'dashboard.filters'
]

app
  .controller 'MemberController', [
    '$http'
    '$scope'
    '$filter'
    'ngTableParams'
    ($http, $scope, $filter, ngTableParams) ->
      member = this
      member.hideFilter = true
      member.members = []
      member.refreshData = () ->
        $http
          .get '/data/members.json'
          .success (data) ->
            member.members = data
            $scope.refresh++
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
      $scope.$watch "exactFilters", () ->
        $scope.refresh++
        return
      , true
      $scope.tableParams = new ngTableParams(
          page: 1,
          count: 25,
        ,
          total: member.members.length,
          getData: ($defer, params) ->
            data = member.members
            data = if params.filter() then $filter('filter')(data, params.filter()) else data
            data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
            data = $filter('filter')(data, $scope.exactFilters, member.processExactFilters)
            params.total data.length
            $defer
              .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
            return
      )
      member.refreshData()
      return
  ]
