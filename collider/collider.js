(function() {
  var createData, drag, dragMove, pLayer, player, render, score, x, y,
    __slice = Array.prototype.slice;

  createData = function() {
    return _.map(_.range(0, 30), function(i) {
      return {
        id: i,
        x: Math.random() * 100,
        y: Math.random() * 100
      };
    });
  };

  x = d3.scale.linear().domain([0, 100]).range([0, 500]);

  y = d3.scale.linear().domain([0, 100]).range([0, 500]);

  score = 0;

  window.vis = d3.select('body').append('svg:svg').attr('width', 500).attr('height', 500);

  pLayer = vis.append('svg:g');

  dragMove = function() {
    var args, px, py;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    px = parseFloat(player.attr('cx')) + d3.event.dx;
    py = parseFloat(player.attr('cy')) + d3.event.dy;
    player.attr('cx', px);
    return player.attr('cy', py);
  };

  drag = d3.behavior.drag().on('drag', dragMove);

  player = pLayer.append('svg:circle').attr('class', 'area').attr('cx', 250).attr('cy', 250).attr('r', 10).call(drag);

  render = function(data, flush) {
    var checkCollision, series, tw, xTweenWithCall, yTweenWithCall,
      _this = this;
    score += 1;
    console.log(score);
    series = vis.selectAll('circle.enemy').data(data, function(d) {
      return d.id;
    });
    series.enter().append('svg:circle').attr('class', 'enemy').attr('cx', function(d) {
      return x(d.x);
    }).attr('cy', function(d) {
      return y(d.y);
    }).attr('r', 10);
    xTweenWithCall = function(d, i, a) {
      return function(t) {
        a = parseFloat(a);
        return a + (x(d.x) - a) * t;
      };
    };
    yTweenWithCall = function(d, i, a) {
      return function(t) {
        a = parseFloat(a);
        return a + (y(d.y) - a) * t;
      };
    };
    checkCollision = function(enemy) {
      var collisionSep, cx, cy, parseAttr, r, seperation;
      parseAttr = function(a) {
        return [parseFloat(enemy.attr(a)), parseFloat(player.attr(a))];
      };
      r = parseAttr('r');
      cx = parseAttr('cx');
      cy = parseAttr('cy');
      seperation = Math.pow(Math.pow(cx[0] - cx[1], 2) + Math.pow(cy[0] - cy[1], 2), 0.5);
      collisionSep = r[0] + r[1];
      if (seperation <= collisionSep) return score = 0;
    };
    tw = function(d) {
      var self, start;
      self = d3.select(this);
      start = [parseFloat(self.attr('cx')), parseFloat(self.attr('cy'))];
      return function(t) {
        var newX, newY;
        checkCollision(self);
        newX = start[0] + (x(d.x) - start[0]) * t;
        newY = start[1] + (y(d.y) - start[1]) * t;
        return self.attr('cx', newX).attr('cy', newY);
      };
    };
    series.transition().duration(2000).tween('foo', tw);
    return series.exit().transition().duration(2000).attr('r', 10).remove();
  };

  setInterval((function() {
    return render(createData());
  }), 2000);

}).call(this);
