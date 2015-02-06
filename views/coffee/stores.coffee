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
      # {{{ store.filterStores = () ->
      store.filterStores = () ->
        data = store.stores
        data = $filter('filter')(data, $scope.filters.normal)
        store.filteredStores = data

      # }}}
      # {{{ store.refreshData = () ->
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
        return

      # }}}
      # {{{ $scope.filters =
      $scope.filters =
        normal:
          active: ''
          name: ''
          full_address: ''

      # }}}
      # {{{ $scope.$watch "refresh", () ->
      $scope.$watch "refresh", () ->
        store.filterStores()
        $scope
          .tableParams
          .reload()
        return

      # }}}
      # {{{ $scope.$watch "filters", () ->
      $scope.$watch "filters", () ->
        $scope.refresh++
        return
      , true

      # }}}
      # {{{ $scope.tableParams = new ngTableParams(
      $scope.tableParams = new ngTableParams(
          page: 1
          count: 10
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

      # }}}
      $scope.refresh = 0
      store.refreshData()
      return
  ]
