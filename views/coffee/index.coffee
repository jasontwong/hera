app = angular.module 'dashboard.index', []

app.controller 'IndexController', [
  'dataFactory'
  '$http'
  '$scope'
  '$modal'
  (dataFactory, $http, $scope, $modal) ->
    index = this
    index.hideFilter = true
    index.data =
      checkins: []
      redeems: []
      surveys: []
    index.mpOptions = [
      'Hour'
      'Day'
      'Month'
    ]
    $scope.data = []
    $scope.mpData = []
    $scope.format = "%_I%p"
    $scope.mpFormat = "%_I%p"
    today = new Date()
    # {{{ index.updateChart = ->
    index.updateChart = ->
      newdata =
        checkins: []
        downloads: []
        redeems: []
        reviews: []
        surveys: []
      predata =
        x: []
        checkins: {}
        downloads: {}
        redeems: {}
        reviews: {}
        surveys: {}
      start = new Date $scope.filters.date.start
      start.setHours(0, 0, 0, 0)
      end = new Date $scope.filters.date.end
      end.setHours(23, 59, 59, 999)
      num_days = (end - start) / (1000 * 60 * 60 * 24)
      $scope.format = switch
        when num_days < 1 then "%_I%p"
        when num_days < 30 then "%m-%d"
        when num_days < 730 then "%b %Y"
        else "%Y"
      $http
        .get(
          '/data/appfigures/reports/sales',
          params:
            start_date: start.getFullYear() + "-" + ('0' + (start.getMonth() + 1)).slice(-2) + "-" + ('0' + start.getDate()).slice(-2)
            end_date: end.getFullYear() + "-" + ('0' + (end.getMonth() + 1)).slice(-2) + "-" + ('0' + end.getDate()).slice(-2)
        )
        .success (sales, status, headers, config) ->
          # {{{ checkin data
          for obj in index.data.checkins
            date = new Date(obj.created_at)
            hours = if num_days < 1 then date.getHours() else 0
            date.setHours(hours, 0, 0, 0)
            if +start <= +date <= +end
              date_format = date.toISOString()
              predata.x.push date_format if date_format not in predata.x
              predata.checkins[date_format] = 0 unless predata.checkins[date_format]?
              predata.checkins[date_format] += 1

          # }}}
          # {{{ redeem data
          for obj in index.data.redeems
            date = new Date(obj.redeemed_at)
            hours = if num_days < 1 then date.getHours() else 0
            date.setHours(hours, 0, 0, 0)
            if +start <= +date <= +end
              date_format = date.toISOString()
              predata.x.push date_format if date_format not in predata.x
              predata.redeems[date_format] = 0 unless predata.redeems[date_format]?
              predata.redeems[date_format] += 1

          # }}}
          # {{{ sales data
          for d, obj of sales
            date = new Date(d)
            tzHours = start.getTimezoneOffset() / 60
            date.setHours(date.getHours() + tzHours, 0, 0, 0)
            if +start <= +date <= +end
              date_format = date.toISOString()
              predata.x.push date_format if date_format not in predata.x
              predata.downloads[date_format] = 0 unless predata.downloads[date_format]?
              predata.downloads[date_format] = obj.downloads

          # }}}
          # {{{ survey data
          for obj in index.data.surveys
            continue if not obj.completed? or obj.completed is not true
            date = new Date(obj.completed_at)
            hours = if num_days < 1 then date.getHours() else 0
            date.setHours(hours, 0, 0, 0)
            if +start <= +date <= +end
              date_format = date.toISOString()
              predata.x.push date_format if date_format not in predata.x
              if obj.answers.length == 0
                predata.reviews[date_format] = 0 unless predata.reviews[date_format]?
                predata.reviews[date_format] += 1
              else
                predata.surveys[date_format] = 0 unless predata.surveys[date_format]?
                predata.surveys[date_format] += 1

          # }}}
          # {{{ cleanup data
          predata.x.sort (a, b) ->
            first = new Date(a)
            second = new Date(b)
            return -1 if +first < +second
            return 1 if +second < +first
            return 0
          totals =
            checkins: 0
            downloads: 0
            redeems: 0
            reviews: 0
            surveys: 0
          x = for date in predata.x
            checkin = predata.checkins[date]
            download = predata.downloads[date]
            redeem = predata.redeems[date]
            review = predata.reviews[date]
            survey = predata.surveys[date]
            checkin_data = if checkin? then checkin else 0
            download_data = if download? then download else 0
            redeem_data = if redeem? then redeem else 0
            review_data = if review? then review else 0
            survey_data = if survey? then survey else 0
            totals.checkins += checkin_data
            totals.downloads += download_data
            totals.redeems += redeem_data
            totals.reviews += review_data
            totals.surveys += survey_data
            newdata.checkins.push checkin_data
            newdata.downloads.push if sales.length > 1 then download_data else 0
            newdata.redeems.push redeem_data
            newdata.reviews.push review_data
            newdata.surveys.push survey_data
            new Date(date)
          $scope.data = [
            ['x'].concat x
            ['Checkins: ' + totals.checkins].concat newdata.checkins
            ['Downloads: ' + totals.downloads].concat newdata.downloads
            ['Redeems: ' + totals.redeems].concat newdata.redeems
            ['Reviews: ' + totals.reviews].concat newdata.reviews
            ['Custom Surveys: ' + totals.surveys].concat newdata.surveys
          ]

          # }}}
          return
        .error ->
          return
      return

    # }}}
    # {{{ index.updateMPChart = ->
    index.updateMPChart = ->
      event = 'Did Become Active'
      $http
        .get(
          '/data/mixpanel/events',
          params:
            event: event
            unit: $scope.filters.mixpanel.users.unit.toLowerCase()
            interval: $scope.filters.mixpanel.users.interval
        )
        .success (data, status, headers, config) ->
          dates = []
          counts = []
          total = 0
          switch $scope.filters.mixpanel.users.unit
            when 'Hour' then $scope.mpFormat = "%_I%p"
            when 'Day' then $scope.mpFormat = "%m-%d"
            when 'Month' then $scope.mpFormat = "%b '%y"
          for x, count of data.data.values[event]
            dates.push Date.parse(x.replace(" ", "T"))
            counts.push count
            total += count
          $scope.mpData = [
            ['x'].concat dates
            ['Users: ' + total].concat counts
          ]
          return
        .error ->
          console.log 'mp error'

    # }}}
    # {{{ index.refreshData = (force) ->
    index.refreshData = (force) ->
      index.modal = $modal.open
        templateUrl: 'loading-modal'
        keyboard: false
        backdrop: 'static'
      closeModal = () ->
        index
          .modal
          .close()
        return
      index
        .modal
        .opened
        .then ->
          dataFactory
            .getCheckins force
            .success (checkins) ->
              dataFactory
                .getRedeems force
                .success (redeems) ->
                  dataFactory
                    .getSurveys force
                    .success (surveys) ->
                      index.data =
                        checkins: checkins
                        redeems: redeems
                        surveys: surveys
                      index.updateChart()
                      closeModal()
                    .error closeModal
                .error closeModal
            .error closeModal
      return

    # }}}
    # {{{ $scope.calendars =
    $scope.calendars =
      config:
        showWeeks: false
      visited:
        end:
          open: false
          toggle: ($event) ->
            $event.preventDefault()
            $event.stopPropagation()
            $scope.calendars.visited.end.open = !$scope.calendars.visited.end.open
            return
        start:
          open: false
          toggle: ($event) ->
            $event.preventDefault()
            $event.stopPropagation()
            $scope.calendars.visited.start.open = !$scope.calendars.visited.start.open
            return

    # }}}
    # {{{ $scope.filters =
    $scope.filters =
      date:
        end: today.toDateString()
        start: today.toDateString()

    # }}}
    # {{{ $scope.$watch "filters", () ->
    $scope.$watch "filters", () ->
      index.updateChart()
      return
    , true

    # }}}
    index.refreshData()
    return
]
