(function() {
  var Player, SocketChannel, axes, createEnemies, gameBoard, gameOptions, gameStats, lastPos, localPlayer, play, players, render, updateBestScore, updateScore;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  players = {};
  SocketChannel = (function() {
    function SocketChannel() {
      this.playerHit = __bind(this.playerHit, this);
      this.emit = __bind(this.emit, this);      this.socket = io.connect('http://192.168.102.5');
      this.socket.on('connect', __bind(function() {
        return this.id = this.socket.socket.sessionid;
      }, this));
      this.socket.on('update-players', __bind(function(data) {
        return _(data.ids).each(__bind(function(id) {
          if (!players[id] && id !== this.id) {
            console.log('Added player', id);
            return players[id] = new Player(gameOptions, false).render(gameBoard);
          }
        }, this));
      }, this));
      this.socket.on('game-client-hit', __bind(function(data) {
        return console.log('Player ' + data.player + ' was hit');
      }, this));
      this.socket.on('game-player-added', __bind(function(id) {
        console.log("Player: " + id + " joined the game!");
        if (!players[id] && id !== this.id) {
          return players[id] = new Player(gameOptions, false).render(gameBoard);
        }
      }, this));
      this.socket.on('game-player-moved', __bind(function(data) {
        if (data.id !== this.id && players[data.id]) {
          return players[data.id].transform({
            x: data.x,
            y: data.y,
            angle: data.a
          });
        }
      }, this));
    }
    SocketChannel.prototype.emit = function() {
      var args, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = this.socket).emit.apply(_ref, args);
    };
    SocketChannel.prototype.playerHit = function() {
      return this.emit('game-client-hit', {
        player: this.id
      });
    };
    return SocketChannel;
  })();
  window.socket = new SocketChannel;
  socket.emit('test');
  gameOptions = {
    height: 450,
    width: 700,
    nEnemies: 30,
    padding: 20
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
  Player = (function() {
    Player.prototype.path = 'm-7.5,1.62413c0,-5.04095 4.08318,-9.12413 9.12414,-9.12413c5.04096,0 9.70345,5.53145 11.87586,9.12413c-2.02759,2.72372 -6.8349,9.12415 -11.87586,9.12415c-5.04096,0 -9.12414,-4.08318 -9.12414,-9.12415z';
    Player.prototype.fill = '#ff6600';
    Player.prototype.x = 0;
    Player.prototype.y = 0;
    Player.prototype.angle = 0;
    Player.prototype.r = 5;
    function Player(gameOptions, moveable) {
      if (moveable == null) {
        moveable = false;
      }
      this.setupDragging = __bind(this.setupDragging, this);
      this.moveRelative = __bind(this.moveRelative, this);
      this.moveAbsolute = __bind(this.moveAbsolute, this);
      this.transform = __bind(this.transform, this);
      this.setY = __bind(this.setY, this);
      this.getY = __bind(this.getY, this);
      this.setX = __bind(this.setX, this);
      this.getX = __bind(this.getX, this);
      this.render = __bind(this.render, this);
      this.gameOptions = gameOptions;
      this.moveable = moveable;
    }
    Player.prototype.render = function(to) {
      this.el = to.append('svg:path').attr('d', this.path).attr('fill', this.fill);
      this.transform({
        x: this.gameOptions.width * 0.5 + (Math.random() * 50) - 100,
        y: this.gameOptions.height * 0.5 + (Math.random() * 50) - 100
      });
      this.setupDragging();
      return this;
    };
    Player.prototype.getX = function() {
      return this.x;
    };
    Player.prototype.setX = function(x) {
      var maxX, minX;
      minX = this.gameOptions.padding;
      maxX = this.gameOptions.width - this.gameOptions.padding;
      if (x <= minX) {
        x = minX;
      }
      if (x >= maxX) {
        x = maxX;
      }
      return this.x = x;
    };
    Player.prototype.getY = function() {
      return this.y;
    };
    Player.prototype.setY = function(y) {
      var maxY, minY;
      minY = this.gameOptions.padding;
      maxY = this.gameOptions.height - this.gameOptions.padding;
      if (y <= minY) {
        y = minY;
      }
      if (y >= maxY) {
        y = maxY;
      }
      return this.y = y;
    };
    Player.prototype.transform = function(opts) {
      this.angle = opts.angle || this.angle;
      this.setX(opts.x || this.x);
      this.setY(opts.y || this.y);
      return this.el.attr('transform', ("rotate(" + this.angle + "," + (this.getX()) + "," + (this.getY()) + ") ") + ("translate(" + (this.getX()) + "," + (this.getY()) + ")"));
    };
    Player.prototype.moveAbsolute = function(x, y) {
      return this.transform({
        x: x,
        y: y
      });
    };
    Player.prototype.moveRelative = function(dx, dy) {
      return this.transform({
        x: this.getX() + dx,
        y: this.getY() + dy,
        angle: 360 * (Math.atan2(dy, dx) / (Math.PI * 2))
      });
    };
    Player.prototype.setupDragging = function() {
      var drag, dragMove;
      if (this.moveable) {
        console.log("enable dragging");
        dragMove = __bind(function() {
          return this.moveRelative(d3.event.dx, d3.event.dy);
        }, this);
        drag = d3.behavior.drag().on('drag', dragMove);
        return this.el.call(drag);
      }
    };
    return Player;
  })();
  localPlayer = new Player(gameOptions, true).render(gameBoard);
  players[socket.id] = localPlayer;
  lastPos = {
    x: 0,
    y: 0
  };
  setInterval((function() {
    if (localPlayer.x !== lastPos.x || localPlayer.y !== lastPos.y) {
      lastPos = {
        x: localPlayer.x,
        y: localPlayer.y
      };
      return socket.emit('game-player-moved', {
        id: socket.id,
        x: localPlayer.x,
        y: localPlayer.y,
        a: localPlayer.angle
      });
    }
  }), 100);
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
    var checkCollision, collisionTimeout, enemies, onCollision, tweenWithCollisionDetection;
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
      return _(players).each(function(player) {
        var radiusSum, separation, xDiff, yDiff;
        radiusSum = parseFloat(enemy.attr('r')) + player.r;
        xDiff = parseFloat(enemy.attr('cx')) - player.x;
        yDiff = parseFloat(enemy.attr('cy')) - player.y;
        separation = Math.sqrt(Math.pow(xDiff, 2) + Math.pow(yDiff, 2));
        if (separation < radiusSum) {
          return collidedCallback(player, enemy);
        }
      });
    };
    collisionTimeout = null;
    onCollision = function() {
      clearTimeout(collisionTimeout);
      collisionTimeout = setTimeout((function() {
        return socket.playerHit();
      }), 300);
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
