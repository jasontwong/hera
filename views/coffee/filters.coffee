app = angular.module('dashboard.filters', [])

# filters
app
  .filter 'unsafe', ($sce) ->
    $sce.trustAsHtml
  .filter "titleCase", ->
    (str) ->
      (if (not str? or str is null) then "" else str.replace(/_|-/, " ").replace(/\w\S*/g, (txt) ->
        txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
      ))
