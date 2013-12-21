@infrastructure = angular.module('infrastructure',[])

@infrastructure.config ($routeProvider) ->
		$routeProvider
    .when('/', {
      templateUrl : 'templates/index.html',
      controller  : 'MainStatsCtrl'
    })
    .when('/cpg', {
      templateUrl : 'templates/cpg_index.html',
      controller  : 'CPGStatsCtrl'
    })

infrastructure.factory 'mapService', ($http) ->
  return {
    districtGeo: $http.get('data/districts.json')
    neighborhoodGeo:$http.get('data/neighborhoods.geojson')
  }
infrastructure.factory 'statsService', ($http) ->
  return {
    statsPromise: $http.get('data/stats.json')
    cpgPerDistrict: $http.get('data/district_projects.csv')
    byDepartment: $http.get('data/district_by_department.csv')
    departments: $http.get('data/department_by_district.csv')
  }

@infrastructure.directive 'districtmap',($http, statsService,mapService) ->
  return {
    restrict: 'E',
    template: '<div id="districts"></div>',
    replace: true
    link: ($scope, element, iAttrs, ctrl) ->
      options = {width: $('#districts').width(), height: 700}
      $scope.map = new DistrictMap("#districts",options)
      mapService.districtGeo.then (response) ->
        $scope.map.drawMap(response.data.features)
        $scope.districtMap = true
  }
@infrastructure.directive 'departmentoverview', (statsService) ->
  return {
    restrict: 'E'
    template: '<div id="department-overview"></div>'
    replace: true
    link: ($scope, element, iAttrs, ctrl) ->
      ''
  }
@infrastructure.controller 'CPGStatsCtrl', ($scope,statsService,mapService) ->
  byDepartment = (department)->
    statsService.byDepartment.then (response) ->
      $scope.stats = d3.csv.parse(response.data)
      $scope.$watch 'districtMap', (newVal, oldVal)->
        if newVal
          $scope.map.byDepartment($scope.stats,department)
          $scope.districtChart.chart($scope.stats,department)
  options = {width: $('#district-info').width(), height: 200, margin: {top: 10, bottom: 20, left: 10, right: 10}}
  $scope.districtChart = new DistrictBarChart("#district-chart",options)
  statsService.departments.then (response) ->
    $scope.departments = d3.csv.parse(response.data)
    $scope.department = $scope.departments[0]
    $scope.$watch 'department', (newVal,oldVal) ->
      byDepartment(newVal.Department)

  statsService.cpgPerDistrict.then (response) ->
    $scope.stats = d3.csv.parse(response.data)
    $scope.$watch 'districtMap', (newVal, oldVal)->
      if newVal
        ''
        #$scope.map.cpgPerDistrict($scope.stats)
        #$scope.districtChart.chart($scope.stats,'Count')
  $scope.showNeighborhoods = ->
    mapService.neighborhoodGeo.then (response) ->
      $scope.map.drawMap(response.data.features)
      $scope.districtMap = true



@infrastructure.controller 'MainStatsCtrl', ($scope,statsService) ->
  statsService.statsPromise.then (response) ->
    $scope.stats = response.data
    $scope.$watch 'districtMap', (newVal, oldVal)->
      if newVal
        $scope.map.districtProjectCosts($scope.stats.districts)

infrastructure.controller 'PhasesCtrl', ($scope,statsService) ->
  statsService.statsPromise.then (response) ->
    $scope.phases = response.data.phases
    #$scope.phaseChunks = phases.chunk(2)
infrastructure.controller 'DistrictCtrl', ($http,$scope,$q,statsService) ->
  width = 660
  height = 660
  svg = d3.select("#districts").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("id", "district-map")
  districtPromise = $q.all([statsService.statsPromise,$http.get('data/districts.json')])
  districtPromise.then (response) ->
    $scope.districts = response[0].data.districts
    $scope.districtFeature = response[1].data.features
    generateMap()
  generateMap = () ->
    districtStatsValues = d3.map($scope.districts).values()
    projectCostMax = d3.max(districtStatsValues, (d) -> return d.project_costs)
    projectCostMin = d3.min(districtStatsValues, (d) -> return d.project_costs)
    quantize = d3.scale.quantize()
    .domain([projectCostMin,projectCostMax])
    .range(d3.range(9).map((i) -> return "q" + i + "-9"))
    projection = d3.geo.mercator()
    .scale(48100)
    .center([-117.15186, 32.82162])
    .translate([width / 2, height / 2])
    path = d3.geo.path()
    .projection(projection)
    svg
    .selectAll("path")
    .data($scope.districtFeature)
    .enter().append("path")
    .attr("d", path)
    .attr("class", (d) -> quantize($scope.districts[d.properties.DISTRICT].project_costs))
    top = [100,355,465,505,100,220,260,555,355]
    left = [180,60,100,580,650,190,610,230,650]
    for feature in $scope.districtFeature
      center = path.centroid(feature)
      d3.select("#district-map").append("line").attr("x1",left[feature.properties.DISTRICT-1]).attr("x2",center[0]).attr("y1",top[feature.properties.DISTRICT-1]).attr("y2",center[1])

Array::chunk = (chunkSize) ->
  array = this
  [].concat.apply [], array.map((elem, i) ->
    (if i % chunkSize then [] else [array.slice(i, i + chunkSize)])
  )

