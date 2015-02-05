app = angular.module 'dashboard.stores', [
  'ngTable'
  'dashboard.filters'
]

app
  .controller 'StoreController', [
    '$http'
    '$scope'
    '$filter'
    '$modal'
    'ngTableParams'
    ($http, $scope, $filter, $modal, ngTableParams) ->
      store = this
      store.hideFilter = true
      store.stores = []
      store.refreshData = () ->
        store.modal = $modal.open
          templateUrl: 'loadingModal'
          keyboard: false
          backdrop: 'static'
        $http
          .get '/data/stores.json'
          .success (data) ->
            store.stores = data
            $scope.refresh++
            store
              .modal
              .close()
            return
      store.processExactFilters = (actual, expected) ->
        return true if expected == "" || expected == null
        return false if actual == undefined
        return actual.toLowerCase() == expected
      $scope.refresh = 0
      $scope.exactFilters = {}
      $scope.filters =
        active: ''
        name: ''
        full_address: ''
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
          total: store.stores.length,
          getData: ($defer, params) ->
            data = store.stores
            data = if params.filter() then $filter('filter')(data, params.filter()) else data
            data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
            data = $filter('filter')(data, $scope.exactFilters, store.processExactFilters)
            params.total data.length
            $defer
              .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
            return
      )
      store.refreshData()
      return
  ]
