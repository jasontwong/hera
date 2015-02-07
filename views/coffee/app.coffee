app = angular.module 'dashboard', [
  'ngRoute'
  'ui.bootstrap'
  'dashboard.filters'
  'dashboard.index'
  'dashboard.members'
  'dashboard.stores'
  'dashboard.surveys'
]

app.value 'stormData',
  members: []
  stores: []
  surveys: []

# config
app.config [
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
      .when '/surveys',
        title: 'Surveys'
        templateUrl: '/tpl/surveys/index.html'
    $locationProvider.html5Mode true
    return
]

# run
app.run [
  '$location'
  '$rootScope'
  '$sce'
  ($location, $rootScope, $sce) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
      $rootScope.title = current.$$route.title
      return
    return
]

# directives
app.directive 'dashboardNav', () ->
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

app.directive 'heraMap', [
  () ->
    restrict: 'EA'
    scope:
      layers: '='
    link: (scope, ele, attrs) ->
      div = d3.select ele[0]
        .append 'div'
        .style 'height', attrs.mapHeight || '180px'
        .style 'width', '100%'
        .classed
          map: true

      # scope.data = [
      #     name: 1
      #     latitude: 41.163048
      #     longitude: -87.876625
      #   ,
      #     name: 2
      #     latitude: 41.9177360534668
      #     longitude: -87.6530075073242
      #   ,
      #     name: 3
      #     latitude: 41.88371166586876,
      #     longitude: -87.62619204819202
      # ]

      scope.oldLayers = {}
      scope.$watch 'layers', (data) ->
        scope.map.removeControl(scope.control) if scope.control?
        scope.map.removeLayer(v) for k,v of scope.oldLayers
        unless angular.equals {}, data
          scope.oldLayers = data
          scope.control = L
            .control
            .layers(null, data)
            .addTo scope.map
        else
          scope.control = null
          scope.oldLayers = {}
        return
      , true

      layer = L.tileLayer 'http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png',
        attribution: ''
        minZoom: 0
        maxZoom: 20
      scope.map = L.map div.node(),
        center: [
          41.881320
          -87.630440
        ]
        zoom: 13
        layers: [layer]
      return
]
