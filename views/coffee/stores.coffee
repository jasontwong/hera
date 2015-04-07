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
        data = $filter('filter')(data, store.processFilters.batt_lvl) if angular.isNumber $scope.filters.batt_lvl.max
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
                dataFactory
                  .getBatteryLevels force
                  .success (battLvls) ->
                    batts = $filter('orderBy')(battLvls, "-read_at")
                    keys = []
                    for obj in data
                      for batt in batts
                        break if obj.key in keys
                        if batt.store_key is obj.key
                          obj.batt_lvl = batt.level
                          obj.read_at = batt.read_at
                          keys.push obj.key
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
              .error ->
                store
                  .modal
                  .close()
                return
        return

      # }}}
      # {{{ store.processFilters =
      store.processFilters =
        batt_lvl: (value, index) ->
          max = parseInt $scope.filters.batt_lvl.max, 10
          valid = true
          valid = value.batt_lvl <= max if valid and !isNaN max
          valid
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
        batt_lvl:
          max: ''

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
