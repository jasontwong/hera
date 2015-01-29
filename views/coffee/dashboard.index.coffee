(($) ->
  $ ->
    spinnerOptions =
      color: "#aaaaaa"
      width: 2
      radius: 5

    statusContainer = document.getElementById("status-message-container")
    size = parseInt(window.getComputedStyle(statusContainer.parentNode).getPropertyValue("height"), 10)
    showUsers = (data) ->
      
      # Convert string data to numbers. 
      data.forEach (d) ->
        d.surveys = parseInt(d.stats.surveys.submitted, 10)
        d.rewards = parseInt(d.stats.rewards.redeemed, 10)
        d.stores = parseInt(d.stats.stores.visits, 10)
        return
      
      # Set up charts. 
      surveysChart = dc.barChart("#users-surveys-chart")
      rewardsChart = dc.barChart("#users-rewards-chart")
      storesChart = dc.barChart("#users-stores-chart")
      
      # Add data to crossfilter. 
      users = crossfilter(data)
      
      # Set up dimensions. 
      surveys = users.dimension((d) ->
        d.surveys
      )
      surveysCount = surveys.group().reduceCount()
      maxSurveys = surveysCount.top(1)[0].value
      rewards = users.dimension((d) ->
        d.rewards
      )
      rewardsCount = rewards.group().reduceCount()
      maxRewards = rewardsCount.top(1)[0].value
      stores = users.dimension((d) ->
        d.stores
      )
      storesCount = stores.group().reduceCount()
      maxVisits = storesCount.top(1)[0].value
      
      # Create visualizations. 
      surveysChart.width(480).height(240).margins(
        top: 10
        right: 10
        bottom: 20
        left: 50
      ).dimension(surveys).group(surveysCount).transitionDuration(500).centerBar(true).gap(1).x(d3.scale.linear().domain([
        0
        50
      ])).y(d3.scale.pow().exponent(0.3).domain([
        0
        maxSurveys
      ])).yAxis().ticks 6
      rewardsChart.width(480).height(240).margins(
        top: 10
        right: 10
        bottom: 20
        left: 50
      ).dimension(rewards).group(rewardsCount).transitionDuration(500).centerBar(true).gap(1).x(d3.scale.linear().domain([
        0
        50
      ])).y(d3.scale.pow().exponent(0.3).domain([
        0
        maxRewards
      ])).yAxis().ticks 6
      storesChart.width(480).height(240).margins(
        top: 10
        right: 10
        bottom: 20
        left: 50
      ).dimension(stores).group(storesCount).transitionDuration(500).centerBar(true).gap(1).x(d3.scale.linear().domain([
        0
        50
      ])).y(d3.scale.pow().exponent(0.3).domain([
        0
        maxVisits
      ])).yAxis().ticks 6
      
      # Render charts. 
      dc.renderAll()
      return

    spinner = undefined
    
    # Add axis labels. 
    #         * See http://bl.ocks.org/phoebebright/3061203.
    #         
    
    # surveysChart
    # 	.svg()
    # 	.append("text")
    # 	.attr("text-anchor", "middle")
    # 	.attr("transform", ["translate(", surveysChart.xAxisPadding()/2, ",", surveysChart.height()/2, ") rotate(-90)"].join('')) 
    # 	.text("Number of users");
    statusContainer.style.width = size + "px"
    statusContainer.style.height = size + "px"
    spinner = new Spinner(spinnerOptions).spin(statusContainer)
    d3.json "/data/members.json", (err, data) ->
      spinner.stop()
      if err
        showError err, statusContainer
      else
        showUsers data
      return

    return

  return
) jQuery
