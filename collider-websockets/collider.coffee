# Collider is a simple game
#
# * we have a player, and some enemies, who move randomly
# * if the player gets hit, our score is reset
# * otherwise our score goes up over time
# * [Play it here](http://latentflip.github.com/LearningD3/collider)

players = {}

class SocketChannel
  constructor: ->
    @socket = io.connect('http://192.168.102.5')
    @socket.on 'connect', =>
      @id = @socket.socket.sessionid

    @socket.on 'update-players', (data) =>
      _(data.ids).each (id) =>
        if !players[id] && id != @id
          console.log('Added player', id)
          players[id] = new Player(gameOptions, false).render(gameBoard)

    @socket.on 'game-client-hit', (data) =>
      console.log('Player '+data.player+' was hit')

    @socket.on 'game-player-added', (id) =>
      console.log "Player: #{id} joined the game!"
      if !players[id] && id != @id
        players[id] = new Player(gameOptions, false).render(gameBoard)

    @socket.on 'game-player-moved', (data) =>
      if data.id != @id && players[data.id]
        players[data.id].transform(x:data.x, y:data.y, angle:data.a)

  emit: (args...) =>
    @socket.emit args...

  playerHit: =>
    @emit 'game-client-hit', {player: @id}
    
window.socket = new SocketChannel
socket.emit('test')


# ## Setup the environment

# Some basic parameters for our game
gameOptions =
  height: 450
  width: 700
  nEnemies: 30
  padding: 20

# Somewhere to dump the score
gameStats =
  score: 0
  bestScore: 0

# ## Setup the game board

# ### Axes

# Our game coordinates range from 0 to 100 in both x and y
# axes. This gets mapped to our pixelled game area using these
# scale functions
axes =
  x: d3.scale.linear().domain([0,100]).range([0,gameOptions.width])
  y: d3.scale.linear().domain([0,100]).range([0,gameOptions.height])

# ### Game Board (svg region)

# This looks like jQuery, and it is.
#
# * find the container element in the DOM
# * append an svg element to it
# * and set some attributes on the element
gameBoard = d3.select('.container').append('svg:svg')
                .attr('width', gameOptions.width)
                .attr('height', gameOptions.height)

# ### Scores

# Update our scoreboard, which is just in an html span
updateScore = ->
  d3.select('#current-score')
      .text(gameStats.score.toString())
      
# Update our best score if current score is bigger, 
# and update the scoreboard
updateBestScore = ->
  gameStats.bestScore =
    _.max [gameStats.bestScore, gameStats.score]

  d3.select('#best-score').text(gameStats.bestScore.toString())




# ## The Player
# The player is a circle that the user can drag around the board with their mouse

# Let's stick everything in a class to keep it clean
class Player
  # An svg path, created using [this tool](http://svg-edit.googlecode.com/svn/branches/2.5.1/editor/svg-editor.html) to give our player a teardrop shape
  path: 'm-7.5,1.62413c0,-5.04095 4.08318,-9.12413 9.12414,-9.12413c5.04096,0 9.70345,5.53145 11.87586,9.12413c-2.02759,2.72372 -6.8349,9.12415 -11.87586,9.12415c-5.04096,0 -9.12414,-4.08318 -9.12414,-9.12415z'

  # Some state for the player to maintain
  fill: '#ff6600'
  x: 0
  y: 0
  angle: 0
  r: 5

  # We need the gameOptions hash to restrict his motion
  constructor: (gameOptions, moveable=false) ->
    @gameOptions = gameOptions
    @moveable = moveable
  
  # Render the path to the gameBoard, and moves it to the middle
  # also initializes dragging on the svg element
  render: (to) =>
    @el = to.append('svg:path')
            .attr('d', @path)
            .attr('fill', @fill)
    @transform
      x: @gameOptions.width * 0.5 + (Math.random() * 50) - 100
      y: @gameOptions.height * 0.5  + (Math.random() * 50) - 100

    @setupDragging()
    this

  # Getters and setters to ensure the player stays within the game
  # boundary
  getX: => @x
  setX: (x) =>
    minX = @gameOptions.padding
    maxX = @gameOptions.width - @gameOptions.padding
    x = minX if x <= minX
    x = maxX if x >= maxX
    @x = x

  getY: => @y
  setY: (y) =>
    minY = @gameOptions.padding
    maxY = @gameOptions.height - @gameOptions.padding
    y = minY if y <= minY
    y = maxY if y >= maxY
    @y = y

  # Since the player is an svg:path, we have to move/rotate him
  # using transform. This method just lets us set any/all of the
  # attributes and the rest will be taken from his internal state
  transform: (opts) =>
    @angle = opts.angle || @angle
    @setX opts.x || @x
    @setY opts.y || @y

    @el.attr 'transform',
      "rotate(#{@angle},#{@getX()},#{@getY()}) "+
      "translate(#{@getX()},#{@getY()})"

  # Moves the player to an absolute position on the gameboard
  moveAbsolute: (x,y) =>
    @transform
      x:x
      y:y

  # Moves the player to a relative position, rotating him based
  # on which direction he is moving
  moveRelative: (dx,dy) =>
    @transform
      x: @getX()+dx
      y: @getY()+dy
      angle: 360 * (Math.atan2(dy,dx)/(Math.PI*2))

  # Use d3's behaviors to make the player draggable
  #
  # * When he is dragged, move him the amount that the mouse
  #   moved (available in the global current user event: d3.event)
  # * Setup dragging using d3's drag behaviour and bind `dragMove`
  #   to the on 'drag' event
  # * Apply the drag behaviour to the player's svg element
  setupDragging: =>
    if @moveable
      console.log "enable dragging"
      dragMove = =>
        @moveRelative(d3.event.dx, d3.event.dy)

      drag = d3.behavior.drag()
              .on('drag', dragMove)
      @el.call(drag)

# Create our player by rendering him to the gameBoard
localPlayer = new Player(gameOptions, true).render(gameBoard)
players[socket.id] = localPlayer
lastPos = {x:0, y:0}
setInterval (->
  if localPlayer.x != lastPos.x or localPlayer.y != lastPos.y
    lastPos = {x:localPlayer.x, y: localPlayer.y}
    socket.emit('game-player-moved', {id: socket.id, x: localPlayer.x, y: localPlayer.y, a: localPlayer.angle})), 100
#players.push new Player(gameOptions).render(gameBoard)



# ## Enemies
# The enemies are an array of simple objects with positions and an id,
# they get rendered and updated in the `render` method

# Creates an array of enemy data with random x and y positions
# by also creating an id, d3 can keep track of the enemies
# and move them rather than creating new ones later
createEnemies = ->
  _.range(0,gameOptions.nEnemies).map (i) ->
    {
      id: i
      x: Math.random()*100
      y: Math.random()*100
    }


# ## Rendering the gameboard
render = (enemy_data) ->
  # Select all the enemies on the board
  # and bind the data to them, using the enemies'
  # id attribute as a key to ensure we update enemies
  # in the future
  enemies = gameBoard.selectAll('circle.enemy')
            .data(enemy_data, (d) -> d.id)

  # ### enter()
  # any enemies which have just entered the game,
  # i.e. who haven't already got a circle bound to
  # an `id` will be in the `enter()` subset, so...
  #
  # * add a class to identify the enemy
  # * position the enemy on tbe board using the axis transforms
  # * start the enemy with no radius (we will increase it threateningly later)
  enemies.enter()
    .append('svg:circle')
      .attr('class', 'enemy')
      .attr('cx', (enemy) -> axes.x(enemy.x))
      .attr('cy', (enemy) -> axes.y(enemy.y))
      .attr('r', 0)

  # ### exit()
  # if we have removed any enemies (currently this won't happen)
  # i.e. a circle is bound to an `id` that is no longer in the 
  # `enemy_data` array, just remove the enemy from the board
  enemies.exit()
    .remove()


  # ### update()
  # If an enemies `id` is already on the board, and is still in
  # the `enemy_data` array, we just want to update the enemies position.
  #
  # We will do this using a custom tween so we can test whether any
  # enemies collide with our player on each step of the animation

  # #### Collision Detection
  # very simple collision detection
  # find the distance between the centers of an enemy and the players
  # and if it's less the sum of their radii, there's been a collision
  # so invoke the callback
  checkCollision = (enemy, collidedCallback) ->
    _(players).each (player) ->
      radiusSum =  parseFloat(enemy.attr('r')) + player.r
      xDiff = parseFloat(enemy.attr('cx')) - player.x
      yDiff = parseFloat(enemy.attr('cy')) - player.y

      separation = Math.sqrt( Math.pow(xDiff,2) + Math.pow(yDiff,2) )
      collidedCallback(player, enemy) if separation < radiusSum

  #If we have a collision, just reset the score
  collisionTimeout = null
  onCollision = ->
    clearTimeout collisionTimeout
    collisionTimeout = setTimeout (-> socket.playerHit()), 300
    updateBestScore()
    gameStats.score = 0
    updateScore()

  # #### Custom Tween
  # Create a custom tween, that tests if the enemy has
  # collided with the player on each tick
  # The tween gets called once at the start of the tween
  # with the data we are tweening to.
  # The tween should yield a function that takes a "timestep" `t`
  # which is between 0 and 1 (0 at the start of the tween, 1 at
  # the end).

  tweenWithCollisionDetection = (endData) ->
    # `this` is our svg element, so wrap with d3
    enemy = d3.select(this)

    # Get the initial position of the enemy 
    startPos =
      x: parseFloat enemy.attr('cx')
      y: parseFloat enemy.attr('cy')

    #Map our endData to endPosition using our axes
    endPos =
      x: axes.x(endData.x)
      y: axes.y(endData.y)

    # Return our custom tween function
    return (t) ->
      checkCollision(enemy, onCollision)
      # Next position, is 
      # `start\_position + (end\_position - start\_position)*timestep
      enemyNextPos =
        x: startPos.x + (endPos.x - startPos.x)*t
        y: startPos.y + (endPos.y - startPos.y)*t

      # Update the enemy's position
      enemy.attr('cx', enemyNextPos.x)
            .attr('cy', enemyNextPos.y)

  # Bind two transitions to the enemies when they are created/updated
  #
  # * The first will grow the enemies radius using a built in tween (the
  #   animation will only show on the first round)
  # * The second uses our custom tween and will run every round to move
  #   the enemies on the board
  enemies
    .transition()
      .duration(500)
      .attr('r', 10)
    .transition()
      .duration(2000)
      .tween('custom', tweenWithCollisionDetection)

# ## Play the game!

# Kick off the game, and set the turn iterations off
#
# * On every turn, update enemy positions, and re-render
# * On every score tick, update the score, and the scoreboard
play = ->
  gameTurn = ->
    newEnemyPositions = createEnemies()
    render(newEnemyPositions)

  increaseScore = ->
    gameStats.score += 1
    updateScore()

  #Take a turn every 2 seconds
  gameTurn()
  setInterval gameTurn, 2000

  #Increment the score counter every 50ms
  setInterval increaseScore, 50

# Play!
play()
