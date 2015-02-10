app = angular.module 'dashboard.index', []

app.controller 'IndexController', [
  'dataFactory'
  '$http'
  '$scope'
  (dataFactory, $http, $scope) ->
    index = this
    index.stores = null
    index.addStoresLayer = (stores) ->
      unless index.stores and angular.equal index.stores, stores
        data = []
        for store in stores
          data.push L.circle [
            store.location.latitude
            store.location.longitude
          ], 30.5,
            fillOpacity: 1
        $scope.layers['Stores'] = L.layerGroup data
      return
    index.updateLayers = (force) ->
      dataFactory
        .getStores force
        .success (data) ->
          index.addStoresLayer data
          return
        .error () ->
          console.log 'get_stores error'
          return
      return
    $scope.layers = {}
    index.updateLayers()
    return
]
