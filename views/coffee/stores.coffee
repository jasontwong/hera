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
      store.filteredStores = []
      store.filterStores = () ->
        data = store.stores
        data = $filter('filter')(data, $scope.filters)
        data = $filter('filter')(data, $scope.exactFilters, store.processExactFilters)
        store.filteredStores = data
      store.refreshData = () ->
        store.modal = $modal.open
          templateUrl: 'loading-modal'
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
          .error () ->
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
      , true
      $scope.$watch "exactFilters", () ->
        $scope.refresh++
        return
      , true
      $scope.tableParams = new ngTableParams(
          page: 1
          count: 25
        ,
          total: store.filteredStores.length
          getData: ($defer, params) ->
            data = store.filteredStores
            data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
            params.total data.length
            $defer
              .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
            return
      )
      store.refreshData()
      return
  ]
