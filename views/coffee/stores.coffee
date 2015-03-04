app = angular.module 'dashboard.stores', [
  'ngTable'
  'dashboard.filters'
]

app
  .controller 'StoreController', [
    'dataFactory'
    '$http'
    '$scope'
    '$filter'
    '$modal'
    'ngTableParams'
    (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
      store = this
      store.hideFilter = true
      store.stores = []
      store.filteredStores = []
      # {{{ store.filterStores = () ->
      store.filterStores = () ->
        data = store.stores
        data = $filter('filter')(data, $scope.filters.normal)
        data = $filter('filter')(data, store.processFilters.surveys) if angular.isNumber($scope.filters.surveys.min) or angular.isNumber $scope.filters.surveys.max
        store.filteredStores = data

      # }}}
      # {{{ store.refreshData = (force) ->
      store.refreshData = (force) ->
        store.modal = $modal.open
          templateUrl: 'loading-modal'
          keyboard: false
          backdrop: 'static'
        store
          .modal
          .opened
          .then ->
            dataFactory
              .getStores force
              .success (data) ->
                store.stores = data
                $scope.refresh++
                store
                  .modal
                  .close()
                return
              .error ->
                store
                  .modal
                  .close()
                return
        return

      # }}}
      # {{{ store.processFilters =
      store.processFilters =
        surveys: (value, index) ->
          min = parseInt $scope.filters.surveys.min, 10
          max = parseInt $scope.filters.surveys.max, 10
          valid = true
          valid = value.stats.surveys.submitted >= min if valid and !isNaN min
          valid = value.stats.surveys.submitted <= max if valid and !isNaN max
          valid

      # }}}
      # {{{ $scope.filters =
      $scope.filters =
        normal:
          active: ''
          name: ''
          full_address: ''
        surveys:
          max: ''
          min: ''

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
