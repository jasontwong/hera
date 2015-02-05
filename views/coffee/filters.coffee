app = angular.module 'dashboard.filters', []

# filters
app
  .filter 'age', () ->
    getAge = (dateString) ->
      today = new Date
      birthDate = new Date(dateString)
      age = today.getFullYear() - birthDate.getFullYear()
      m = today.getMonth() - birthDate.getMonth()
      age-- if m < 0 or (m == 0 and today.getDate() < birthDate.getDate())
      age
  .filter 'unsafe', ($sce) ->
    $sce.trustAsHtml
  .filter "titleCase", ->
    (str) ->
      (if (not str? or str is null) then "" else str.replace(/_|-/, " ").replace(/\w\S*/g, (txt) ->
        txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
      ))
  .filter 'tel', ->
    (tel) ->
      return '' if !tel
      value = tel.toString().trim().replace(/[^0-9]/g, '')
      country = undefined
      city = undefined
      number = undefined
      switch value.length
        when 10
          # +1PPP####### -> C (PPP) ###-####
          country = 1
          city = value.slice(0, 3)
          number = value.slice(3)
        when 11
          # +CPPP####### -> CCC (PP) ###-####
          country = value[0]
          city = value.slice(1, 4)
          number = value.slice(4)
        when 12
          # +CCCPP####### -> CCC (PP) ###-####
          country = value.slice(0, 3)
          city = value.slice(3, 5)
          number = value.slice(5)
        else
          return tel
      country = '' if country == 1
      number = number.slice(0, 3) + '-' + number.slice(3)
      (country + ' (' + city + ') ' + number).trim()
