app = angular.module('dashboard', [
  'ngRoute'
]).config(['$routeProvider', '$locationProvider',
  ($routeProvider, $locationProvider) ->
    $routeProvider.when('/',
      templateUrl: '/tpl/index.html'
    ).when('/members',
      templateUrl: '/tpl/members/index.html'
    ).otherwise(
      redirectTo: '/'
    )
    $locationProvider.html5Mode(true)
    return
])
