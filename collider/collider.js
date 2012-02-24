(function() {
  var axes, createEnemies, drag, dragMove, gameBoard, gameOptions, gameStats, play, player, render, updateBestScore, updateScore;

  gameOptions = {
    height: 450,
    width: 700,
    nEnemies: 30
  };

  gameStats = {
    score: 0,
    bestScore: 0
  };

  axes = {
    x: d3.scale.linear().domain([0, 100]).range([0, gameOptions.width]),
    y: d3.scale.linear().domain([0, 100]).range([0, gameOptions.height])
  };

  gameBoard = d3.select('.container').append('svg:svg').attr('width', gameOptions.width).attr('height', gameOptions.height);

  updateScore = function() {
    return d3.select('#current-score').text(gameStats.score.toString());
  };

  updateBestScore = function() {
    gameStats.bestScore = _.max([gameStats.bestScore, gameStats.score]);
    return d3.select('#best-score').text(gameStats.bestScore.toString());
  };

  player = gameBoard.append('svg:circle').attr('class', 'area').attr('cx', gameOptions.width * 0.5).attr('cy', gameOptions.height * 0.5).attr('r', 10);

  dragMove = function() {
    var newX, newY;
    newX = parseFloat(player.attr('cx')) + d3.event.dx;
    newY = parseFloat(player.attr('cy')) + d3.event.dy;
    player.attr('cx', newX);
    return player.attr('cy', newY);
  };

  drag = d3.behavior.drag().on('drag', dragMove);

  player.call(drag);

  createEnemies = function() {
    return _.range(0, gameOptions.nEnemies).map(function(i) {
      return {
        id: i,
        x: Math.random() * 100,
        y: Math.random() * 100
      };
    });
  };

  render = function(enemy_data) {
    var checkCollision, enemies, onCollision, tweenWithCollisionDetection;
    enemies = gameBoard.selectAll('circle.enemy').data(enemy_data, function(d) {
      return d.id;
    });
    enemies.enter().append('svg:circle').attr('class', 'enemy').attr('cx', function(enemy) {
      return axes.x(enemy.x);
    }).attr('cy', function(enemy) {
      return axes.y(enemy.y);
    }).attr('r', 0);
    enemies.exit().remove();
    checkCollision = function(enemy, collidedCallback) {
      var radiusSum, separation, xDiff, yDiff;
      radiusSum = parseFloat(enemy.attr('r')) + parseFloat(player.attr('r'));
      xDiff = parseFloat(enemy.attr('cx')) - parseFloat(player.attr('cx'));
      yDiff = parseFloat(enemy.attr('cy')) - parseFloat(player.attr('cy'));
      separation = Math.sqrt(Math.pow(xDiff, 2) + Math.pow(yDiff, 2));
      if (separation < radiusSum) return collidedCallback(enemy);
    };
    onCollision = function() {
      updateBestScore();
      gameStats.score = 0;
      return updateScore();
    };
    tweenWithCollisionDetection = function(endData) {
      var endPos, enemy, startPos;
      enemy = d3.select(this);
      startPos = {
        x: parseFloat(enemy.attr('cx')),
        y: parseFloat(enemy.attr('cy'))
      };
      endPos = {
        x: axes.x(endData.x),
        y: axes.y(endData.y)
      };
      return function(t) {
        var enemyNextPos;
        checkCollision(enemy, onCollision);
        enemyNextPos = {
          x: startPos.x + (endPos.x - startPos.x) * t,
          y: startPos.y + (endPos.y - startPos.y) * t
        };
        return enemy.attr('cx', enemyNextPos.x).attr('cy', enemyNextPos.y);
      };
    };
    return enemies.transition().duration(500).attr('r', 10).transition().duration(2000).tween('custom', tweenWithCollisionDetection);
  };

  play = function() {
    var gameTurn, increaseScore;
    gameTurn = function() {
      var newEnemyPositions;
      newEnemyPositions = createEnemies();
      return render(newEnemyPositions);
    };
    increaseScore = function() {
      gameStats.score += 1;
      return updateScore();
    };
    gameTurn();
    setInterval(gameTurn, 2000);
    return setInterval(increaseScore, 50);
  };

  play();

}).call(this);
