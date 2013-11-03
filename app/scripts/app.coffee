$ ->
  width = 660
  height = 660
  svg = d3.select("#districts").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("id", "district-map")
    d3.json "data/districts.json", (error, districts) ->
      d3.json "data/stats.json", (error,stats) ->
        districtStats = stats.districts
        districtStatsValues = d3.map(districtStats).values()
        projectCostMax = d3.max(districtStatsValues, (d) -> return d.project_costs)
        projectCostMin = d3.min(districtStatsValues, (d) -> return d.project_costs)
        quantize = d3.scale.quantize()
        .domain([projectCostMin,projectCostMax])
        .range(d3.range(9).map((i) -> return "q" + i + "-9"))
        projection = d3.geo.mercator()
        .scale(48100)
        .center([-117.15186, 32.82162])
        #.center([-116.25,32.7833333333333])
        .translate([width / 2, height / 2])
        path = d3.geo.path()
        .projection(projection)
        svg
        .selectAll("path")
        .data(districts.features)
        .enter().append("path")
        .attr("d", path)
        .attr("class", (d) -> quantize(districtStats[d.properties.DISTRICT].project_costs))

        top = [100,355,465,505,100,220,260,555,355]
        left = [180,60,100,580,650,190,610,230,650]
        for feature in districts.features
          center = path.centroid(feature)
          infoWindow = d3.select("#districts").append("div")
          .attr("class","district-info-window")
          .attr("id","district-#{feature.properties.DISTRICT}")
          infoWindow.append("h1")
          .text("$#{districtStats[feature.properties.DISTRICT].project_cost_money_string}")
          infoWindow.append("h2")
          .text("#{districtStats[feature.properties.DISTRICT].project_count} projects")
          infoWindow.append("div")
          .attr("class", "district-nr")
          .text("#{feature.properties.DISTRICT}")
          d3.select("#district-map").append("line").attr("x1",left[feature.properties.DISTRICT-1]).attr("x2",center[0]).attr("y1",top[feature.properties.DISTRICT-1]).attr("y2",center[1])



