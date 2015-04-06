# {{{ app = angular.module 'dashboard'
app = angular.module 'dashboard', [
  'ngRoute'
  'ui.bootstrap'
  'dashboard.filters'
  'dashboard.index'
  'dashboard.members'
  'dashboard.stores'
  'dashboard.surveys'
  'dashboard.checkins'
  'dashboard.emails'
  'dashboard.redeems'
]

# }}}
# {{{ app.config
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
      .when '/checkins',
        title: 'Checkins'
        templateUrl: '/tpl/checkins/index.html'
      .when '/redeems',
        title: 'Redeems'
        templateUrl: '/tpl/redeems/index.html'
      .when '/emails',
        title: 'Email Q'
        templateUrl: '/tpl/emails/index.html'
    $locationProvider.html5Mode true
    return
]

# }}}
# {{{ app.run
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

# }}}
# {{{ app.directive 'dashboardNav'
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
        link: '/checkins'
        name: 'Checkins'
      ,
        link: '/redeems'
        name: 'Redeems'
      ,
        link: '/emails'
        name: 'Email Q'
    ]
    $scope.isActive = (location) ->
      location == $location.path()
    return
  controllerAs: 'nav'

# }}}
# {{{ app.directive 'heraMap'
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

      scope.$on '$destroy', ->
        scope.map.remove()
        return

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

# }}}
# {{{ app.directive 'heraLineChart'
app.directive 'heraLineChart', [
  ->
    restrict: 'EA'
    scope:
      data: '=chartData'
      format: '=timeFormat'
    link: (scope, ele, attrs) ->
      chart = c3.generate
        bindto: ele[0]
        data:
          x: 'x'
          columns: []
        axis:
          x:
            type: 'timeseries'
            tick:
              format: (x) ->
                d3.time.format(scope.format)(x)
        tooltip:
          format:
            name: (name, ratio, id, index) ->
              name.replace(/:\s\w+/, "")
          position: (data, width, height, element) ->
            chartOffsetX = element.getBoundingClientRect().left
            graphOffsetX = element.getBoundingClientRect().right
            x = parseInt(element.getAttribute('x')) + graphOffsetX - chartOffsetX - Math.floor(width / 2)
            y = element.getAttribute('y') - height - 14
            {
              top: y
              left: x
            }

      # on window resize, re-render d3 canvas
      window.onresize = ->
        scope.$apply()

      scope.$watch (->
        angular.element(window)[0].innerWidth
      ), ->
        scope.render scope.data

      # watch for data changes and re-render
      scope.$watch 'data', ((newVals, oldVals) ->
        scope.render newVals
      ), true

      # define render function
      scope.render = (data) ->
        chart.load
          columns: data
          unload: true
        chart.flush()
        return
      return
]

# }}}
# {{{ app.factory 'dataFactory'
app.factory 'dataFactory', [
  '$http'
  ($http) ->
    dataBase = '/data'
    getData = (key) -> $http.get dataBase + '/' + key + '.json'
    api = promises = {}
    api.getMembers = (force) ->
      force = force or false
      return promises.members if promises.members? and not force
      promises.members = getData 'members'
    api.getRedeems = (force) ->
      force = force or false
      return promises.redeems if promises.redeems? and not force
      promises.redeems = getData 'redeems'
    api.getStores = (force) ->
      force = force or false
      return promises.stores if promises.stores? and not force
      promises.stores = getData 'stores'
    api.getSurveys = (force) ->
      force = force or false
      return promises.surveys if promises.surveys? and not force
      promises.surveys = getData 'surveys'
    api.getCheckins= (force) ->
      force = force or false
      return promises.checkins if promises.checkins? and not force
      promises.checkins = getData 'checkins'
    api.getEmails = (force) ->
      $http.get dataBase + '/queues/feedback.json'
    api
]

# }}}
