app = angular.module('dashboard.members', [
  'ngTable',
  'dashboard.filters'
])

app
  .controller('MemberController', ['$http', '$scope', 'ngTableParams'
    ($http, $scope, ngTableParams) ->
      member = this
      member.members = []
      $http
        .get('/data/members.json')
        .success((data) ->
          member.members = data
          $scope.tableParams = new ngTableParams(
              page: 1,
              count: 25,
            ,
              total: member.members.length,
              getData: ($defer, params) ->
                $defer.resolve(data.slice((params.page() - 1) * params.count(), params.page() * params.count()));
                return
          )
          return
        )
      return
  ])
