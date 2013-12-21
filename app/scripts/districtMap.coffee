class @DistrictMap extends D3Chart
  constructor: (element, @options = {}) ->
    super(element,@options)
    projection = d3.geo.mercator()
    .scale(48100)
    .center([-117.15186, 32.82162])
    .translate([@width / 2, @height / 2])
    @path = d3.geo.path()
    .projection(projection)
  cpgPerDistrict: (@districts) ->
    minmax = @minMax(@districts, 'Count')
    @quantize = d3.scale.quantize()
    .domain(minmax)
    .range(d3.range(8).map((i) -> return "gb" + i + "-8"))
    @mainGroup().selectAll("path")
    .data(@data)
    .attr("class", (d) => @quantize(@districts[d.properties.DISTRICT-1].Count))
  byDepartment: (@districts,department) ->
    minmax = @minMax(@districts,department)
    @quantize = d3.scale.quantize()
    .domain(minmax)
    .range(d3.range(8).map((i) -> return "gb" + i + "-8"))
    @mainGroup().selectAll("path")
    .data(@data)
    .attr("class", (d) => @quantize(@districts[d.properties.DISTRICT-1][department]))

  districtProjectCosts: (@districts) ->
    districtStatsValues = d3.map(@districts).values()
    projectCostMax = d3.max(districtStatsValues, (d) -> return d.project_costs)
    projectCostMin = d3.min(districtStatsValues, (d) -> return d.project_costs)
    @quantize = d3.scale.quantize()
    .domain([projectCostMin,projectCostMax])
    .range(d3.range(9).map((i) -> return "q" + i + "-9"))
    @mainGroup().selectAll("path")
    .data(@data)
    .attr("class", (d) => @quantize(@districts[d.properties.DISTRICT].project_costs))

  drawMap: (@data) ->
    @mainGroup().selectAll("path")
      .data(@data)
      .enter()
      .append("path")
      .attr("d",@path)
