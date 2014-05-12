@mainChart = () ->
  $('#main-container').highcharts(
    credits:
      enabled: false
    chart:
      type: 'column'
    title:
      text: ''
    xAxis:
      categories: ['<10', '<20', '<30', '<40', '<50', '<60', '<70', '<80', '<90', '<100', '<110', '<120', '<130','<140', '<150', '<160']
      title:
        text: 'Events Per Hour'
    yAxis:
      min: 0
      title:
        text: 'Subjects'
    plotOptions:
      column:
        # dataLabels:
          # enabled: true
        enableMouseTracking: false
    series: [{
      showInLegend: false,
      data: [3142, 1374, 607, 301, 164, 101, 66, 20, 13, 7, 4, 4, 0, 0, 0, 1]
    }]
  )

@chartsReady = () ->
  $('#container').highcharts(
    credits:
      enabled: false
    chart:
      type: 'column'
    title:
      text: 'RDI3P by Visit'
    subtitle:
      text: 'SHHS'
    xAxis:
      categories: ['Visit 1', 'Visit 2']
    yAxis:
      min: 0
      title:
        text: 'Events Per Hour'
    tooltip:
      headerFormat: '<span style="font-size:10px">{point.key}</span><table>'
      pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' + '<td style="padding:0"><b>{point.y:.1f} events per hour</b></td></tr>'
      footerFormat: '</table>'
      shared: true,
      useHTML: true
    plotOptions:
      column:
        pointPadding: 0.2
        borderWidth: 0
        dataLabels:
          enabled: true
        # enableMouseTracking: false
    series: [{
      name: 'Mean RDI3P',
      data: [13.7, 10.3]
    }]
  )

@loadChartRace = () ->
  $('#container').highcharts(
    credits:
      enabled: false
    chart:
      type: 'column'
    title:
      text: 'RDI3P by Visit'
    subtitle:
      text: 'By Race'
    xAxis:
      categories: ['Visit 1', 'Visit 2']
    yAxis:
      min: 0
      title:
        text: 'Events Per Hour'
    tooltip:
      headerFormat: '<span style="font-size:10px">{point.key}</span><table>'
      pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' + '<td style="padding:0"><b>{point.y:.1f} events per hour</b></td></tr>'
      footerFormat: '</table>'
      shared: true,
      useHTML: true
    plotOptions:
      column:
        pointPadding: 0.2
        borderWidth: 0
        dataLabels:
          enabled: true
    series: [{
      name: 'White',
      data: [13.9, 10.4]
    },{
      name: 'Black',
      data: [13.7, 10.9]
    },{
      name: 'Native American / Alaskan',
      data: [11.5, 3.3]
    },{
      name: 'Asian / Pacific Islander',
      data: [9.4, 6.6]
    },{
      name: 'Hispanic / Mexican American',
      data: [12.2, 10.0]
    },{
      name: 'Other',
      data: [7.9, 2.4]
    }]
  )

@loadChartGender = () ->
  $('#container').highcharts(
    credits:
      enabled: false
    chart:
      type: 'column'
    title:
      text: 'RDI3P by Visit'
    subtitle:
      text: 'By Gender'
    xAxis:
      categories: ['Visit 1', 'Visit 2']
    yAxis:
      min: 0
      title:
        text: 'Average Events Per Hour'
    tooltip:
      headerFormat: '<span style="font-size:10px">{point.key}</span><table>'
      pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' + '<td style="padding:0"><b>{point.y:.1f} events per hour</b></td></tr>'
      footerFormat: '</table>'
      shared: true,
      useHTML: true
    plotOptions:
      column:
        pointPadding: 0.2
        borderWidth: 0
        dataLabels:
          enabled: true
    series: [{
      name: 'Male',
      data: [17.5, 13.1]
    },{
      name: 'Female',
      data: [10.3, 8.0],
      color: 'pink'
    }]
  )

@loadChartAge = () ->
  $('#container').highcharts(
    credits:
      enabled: false
    chart:
      type: 'column'
    title:
      text: 'RDI3P by Age'
    subtitle:
      text: 'Visit 1'
    xAxis:
      categories: ['39 to 55 years', '56 to 63 years', '64 to 72 years', '73+ years']
    yAxis:
      min: 0
      title:
        text: 'Average Events Per Hour'
    tooltip:
      headerFormat: '<span style="font-size:10px">{point.key}</span><table>'
      pointFormat: '<tr><td>Visit</td><td style="padding-left:10px">Mean</td><td style="padding-left:10px">StdDev</td><td style="padding-left:10px">Median</td><td style="padding-left:10px">Min</td><td style="padding-left:10px">Max</td><td style="padding-left:10px">N</td></tr>' +
                   '<tr><td style="color:{series.color}">{series.name}</td><td style="padding-left:10px"><b>{point.y:.1f}</b></td><td style="padding-left:10px"><b>&plusmn; {point.stddev:.1f}</b></td><td style="padding-left:10px"><b>{point.median:.1f}</b></td><td style="padding-left:10px"><b>{point.min:.1f}</b></td><td style="padding-left:10px"><b>{point.max:.1f}</b></td><td style="padding-left:10px"><b>{point.n}</b></td></tr>'
      footerFormat: '</table>'
      shared: true,
      useHTML: true
    plotOptions:
      column:
        pointPadding: 0.2
        borderWidth: 0
        dataLabels:
          enabled: true
    series: [{
      name: 'Visit 1',
      data: [{ y: 10.7, stddev: 14.1, median:  5.7, min: 0.0, max: 116.8, n: '1,451' },
             { y: 13.2, stddev: 14.9, median:  8.3, min: 0.0, max: 111.7, n: '1,451' },
             { y: 15.5, stddev: 15.5, median: 10.9, min: 0.0, max: 115.6, n: '1,451' },
             { y: 15.7, stddev: 14.7, median: 11.4, min: 0.0, max: 157.2, n: '1,451' }]
    }]
  )

@toggleButtonClasses = () ->
  $("[data-object~='chart-button']").removeClass('btn-primary').addClass('btn-default')

$(document)
  .on('click', "[data-chart]", () ->
    toggleButtonClasses()
    $("[data-object~='chart-button'][data-chart~='#{$(this).data('chart')}']").addClass('btn-primary')
    if $(this).data('chart') == 'stats'
      $('#container').hide()
      $('#container-stats').show()
    else if $(this).data('chart') == 'overall'
      $('#container-stats').hide()
      $('#container').show()
      chartsReady()
    else if $(this).data('chart') == 'age'
      $('#container-stats').hide()
      $('#container').show()
      loadChartAge()
    else if $(this).data('chart') == 'gender'
      $('#container-stats').hide()
      $('#container').show()
      loadChartGender()
    else if $(this).data('chart') == 'race'
      $('#container-stats').hide()
      $('#container').show()
      loadChartRace()
    false
  )

jQuery ->
  mainChart()
  chartsReady()
