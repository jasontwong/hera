app = angular.module 'dashboard.index', [
]

app.controller 'IndexController', [
  'stormData'
  '$http'
  '$scope'
  (stormData, $http, $scope) ->
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
    index.getData = (key) -> $http.get '/data/' + key + '.json'
    index.updateLayers = () ->
      if stormData.stores.length == 0
        get_stores = index.getData('stores')
        get_stores
          .success (data) ->
            stormData.stores = data
            index.addStoresLayer data
            return
          .error () ->
            console.log 'get_stores error'
            return
      else
        index.addStoresLayer stormData.stores
      return
    $scope.layers = {}
    index.updateLayers()
]
