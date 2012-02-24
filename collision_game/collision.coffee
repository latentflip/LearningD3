
createData = ->
  _.map _.range(0,30), (i) ->
    {
      id: i
      x: Math.random()*100
      y: Math.random()*100
    }

x = d3.scale.linear().domain([0,100]).range([0,500])
y = d3.scale.linear().domain([0,100]).range([0,500])

score = 0

window.vis = d3.select('body').append('svg:svg')
          .attr('width', 500)
          .attr('height', 500)

pLayer = vis.append('svg:g')

dragMove = (args...) ->
  px = parseFloat(player.attr('cx'))  + d3.event.dx
  py = parseFloat(player.attr('cy')) + d3.event.dy
  player.attr('cx', px)
  player.attr('cy', py)

drag = d3.behavior.drag()
        .on('drag', dragMove)

player = pLayer.append('svg:circle')
              .attr('class', 'area')
              .attr('cx', 250)
              .attr('cy', 250)
              .attr('r', 10)
              .call(drag)

render = (data, flush) ->
  score += 1
  console.log(score)

  series = vis.selectAll('circle.enemy')
            .data(data, (d) -> d.id)

  series.enter()
    .append('svg:circle')
      .attr('class', 'enemy')
      .attr('cx', (d) -> x(d.x))
      .attr('cy', (d) -> y(d.y))
      .attr('r', 10)
      #.transition()
      #  .duration(1000)
      #  .attr('r', 10)

  xTweenWithCall = (d,i,a) =>
    (t) ->
      a = parseFloat(a)
      a + (x(d.x) - a)*t

  yTweenWithCall = (d,i,a) =>
    (t) ->
      a = parseFloat(a)
      a + (y(d.y)-a)*t

  checkCollision = (enemy) =>
    parseAttr = (a) ->
      [
        parseFloat(enemy.attr(a))
        parseFloat(player.attr(a))
      ]

    r = parseAttr('r')
    cx = parseAttr('cx')
    cy = parseAttr('cy')

    seperation = Math.pow(
      (Math.pow(cx[0] - cx[1], 2) + Math.pow(cy[0] - cy[1], 2))
      0.5
    )
    collisionSep = r[0] + r[1]
    if seperation <= collisionSep
      score = 0

  tw = (d) ->
    self = d3.select(@)
    start = [
      parseFloat self.attr('cx')
      parseFloat self.attr('cy')
    ]
    (t) ->
      checkCollision(self)
      newX = start[0] + (x(d.x)-start[0])*t
      newY = start[1] + (y(d.y)-start[1])*t
      self
        .attr('cx', newX)
        .attr('cy', newY)

  series.transition()
    .duration(2000)
    .tween('foo', tw)
    #.attrTween('cx', xTweenWithCall)
    #.attrTween('cy', yTweenWithCall)
    #.attr('cx', (d) -> x(d.x))
    #.attr('cy', (d) -> y(d.y))

  series.exit()
    .transition()
      .duration(2000)
      .attr('r', 10)
      .remove()

setInterval (-> render createData()), 2000
