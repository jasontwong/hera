app = angular.module 'dashboard.redeems', [
  'ngTable'
  'dashboard.filters'
]

app.controller 'RedeemController', [
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
      data = $filter('filter')(data, redeem.processFilters.redeemed) if $scope.filters.date.redeemed.start? or $scope.filters.date.redeemed.end?
      redeem.filteredRedeems = data

    # }}}
    # {{{ redeem.refreshData = (force) ->
    redeem.refreshData = (force) ->
      redeem.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      closeModal = () ->
        redeem
          .modal
          .close()
        return
      redeem
        .modal
        .opened
        .then ->
          dataFactory
            .getRedeems force
            .success (data) ->
              dataFactory
                .getMembers force
                .success (members) ->
                  dataFactory
                    .getStores force
                    .success (stores) ->
                      storesFound = {}
                      membersFound = {}
                      for obj in data
                        member = membersFound[obj.member_key] || $filter('findBy')(members, 'key', obj.member_key)
                        if member?
                          membersFound[obj.member_key] = member
                          obj.member = member
                        store = storesFound[obj.store_key] || $filter('findBy')(stores, 'key', obj.store_key)
                        if store?
                          storesFound[obj.store_key] = store
                          obj.store = store
                      redeem.redeems = data
                      $scope.refresh++
                      closeModal()
                      return
                    .error closeModal
                .error closeModal
            .error closeModal
      return

    # }}}
    # {{{ redeem.processFilters =
    redeem.processFilters =
      date: (dates, check_time) ->
        start = if dates.start? then new Date(dates.start) else NaN
        end = if dates.end? then new Date(dates.end) else NaN
        valid = true
        if valid and not isNaN start
          start.setHours(0, 0, 0, 0)
          valid = check_time >= +start
        if valid and not isNaN end
          end.setHours(23, 59, 59, 999)
          valid = check_time <= +end
        valid
      redeemed: (value, index) ->
        redeem.processFilters.date $scope.filters.date.redeemed, value.redeemed_at

    # }}}
    # {{{ $scope.filters =
    $scope.filters =
      normal:
        title: ''
        store:
          name: ''
        member:
          email: ''
      date:
        redeemed:
          start: null
          end: null

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
        sorting:
          redeemed_at: 'desc'
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
