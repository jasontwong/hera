app = angular.module 'dashboard', [
  'ngRoute'
  'ui.bootstrap'
  'dashboard.filters'
  'dashboard.index'
  'dashboard.members'
  'dashboard.stores'
]

# config
app
  .config [
    '$routeProvider'
    '$locationProvider'
    ($routeProvider, $locationProvider) ->
      $routeProvider
        .when '/',
          title: 'Overview'
          templateUrl: '/tpl/index.html'
        .when '/members',
          title: 'Members'
          templateUrl: '/tpl/members/index.html'
        .when '/stores',
          title: 'Stores'
          templateUrl: '/tpl/stores/index.html'
      $locationProvider
        .html5Mode true
      return
  ]

# run
app
  .run [
    '$location'
    '$rootScope'
    '$sce'
    ($location, $rootScope, $sce) ->
      $rootScope
        .$on '$routeChangeSuccess', (event, current, previous) ->
          $rootScope.title = current.$$route.title
          return
      return
  ]

# directives
app
  .directive 'dashboardNav', () ->
    restrict: 'E'
    templateUrl: '/tpl/dashboard/nav.html'
    controller: ($scope, $location) ->
      this.links = [
          link: '/'
          name: 'Overview'
        ,
          link: '/members'
          name: 'Members'
        ,
          link: '/stores'
          name: 'Stores'
        ,
          link: '/surveys'
          name: 'Surveys'
        ,
      ]
      $scope.isActive = (location) ->
        location == $location.path()
      return
    controllerAs: 'nav'
