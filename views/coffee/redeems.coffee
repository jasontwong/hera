app = angular.module 'dashboard.redeems', [
  'ngTable'
  'dashboard.filters'
]

app
  .controller 'RedeemController', [
    'dataFactory'
    '$http'
    '$scope'
    '$filter'
    '$modal'
    'ngTableParams'
    (dataFactory, $http, $scope, $filter, $modal, ngTableParams) ->
      redeem = this
      redeem.hideFilter = true
      redeem.redeems = []
      redeem.filteredRedeems = []
      # {{{ redeem.filterRedeems = () ->
      redeem.filterRedeems = () ->
        data = redeem.redeems
        data = $filter('filter')(data, $scope.filters.normal)
        redeem.filteredRedeems = data

      # }}}
      # {{{ redeem.refreshData = (force) ->
      redeem.refreshData = (force) ->
        redeem.modal = $modal.open
          templateUrl: 'loading-modal'
          keyboard: false
          backdrop: 'static'
        redeem
          .modal
          .opened
          .then ->
            dataFactory
              .getRedeems force
              .success (data) ->
                redeem.redeems = data
                $scope.refresh++
                redeem
                  .modal
                  .close()
                return
              .error ->
                redeem
                  .modal
                  .close()
                return
        return

      # }}}
      # {{{ redeem.processFilters =
      redeem.processFilters =
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
          title: ''

      # }}}
      # {{{ $scope.$watch "refresh", () ->
      $scope.$watch "refresh", () ->
        redeem.filterRedeems()
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
          total: redeem.filteredRedeems.length
          getData: ($defer, params) ->
            data = redeem.filteredRedeems
            data = if params.sorting() then $filter('orderBy')(data, params.orderBy()) else data
            params.total data.length
            $defer
              .resolve data.slice (params.page() - 1) * params.count(), params.page() * params.count()
            return
      )

      # }}}
      $scope.refresh = 0
      redeem.refreshData()
      return
  ]
