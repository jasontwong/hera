app = angular.module('dashboard', [
  'ngRoute'
])

# config
app.config(['$routeProvider', '$locationProvider',
  ($routeProvider, $locationProvider) ->
    $routeProvider.when('/',
      title: 'Overview'
      templateUrl: '/tpl/index.html'
    ).when('/members',
      title: 'Members'
      templateUrl: '/tpl/members/index.html'
    )
    $locationProvider.html5Mode(true)
    return
])

# run
app.run(['$location', '$rootScope', '$sce',
  ($location, $rootScope, $sce) ->
    $rootScope.$on('$routeChangeSuccess', (event, current, previous) ->
      $rootScope.title = current.$$route.title
      return
    )
    return
])

# filters
app.filter('unsafe', ($sce) ->
  $sce.trustAsHtml
)

# directives
app.directive('dashboard-nav', () ->
  restrict: 'E'
  templateUrl: '/tpl/dashboard/nav.html'
)
