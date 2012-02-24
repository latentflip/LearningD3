# Collider is a simple game
#
# * we have a player, and some enemies, who move randomly
# * if the player gets hit, our score is reset
# * otherwise our score goes up over time


# ## Setup the environment

# Some basic parameters for our game
gameOptions =
  height: 450
  width: 700
  nEnemies: 30

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

# Create a player by appending a circle to the middle of the 
# gameboard, 
player = gameBoard.append('svg:circle')
                    .attr('class', 'area')
                    .attr('cx', gameOptions.width*0.5)
                    .attr('cy', gameOptions.height*0.5)
                    .attr('r', 10)
                    
# ### Dragging callback

# We want to be able to drag the player, so we need a callback to update
# the player's position when we drag him
# 
# * Get the current x and y positions of the player (cx, cy)
# * add the delta x and y from the drag event
#   (the current user event is always available in d3.event, and
#   since it's a drag event we can get dx and dy attributes)
# * Update the player's position
dragMove = ->
  newX = parseFloat(player.attr('cx')) + d3.event.dx
  newY = parseFloat(player.attr('cy')) + d3.event.dy
  player.attr('cx', newX)
  player.attr('cy', newY)


# Create the drag behaviour, and attach our `dragMove` callback
drag = d3.behavior.drag()
        .on('drag', dragMove)

# Attach the drag behaviour to the player
player.call(drag)



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
  # find the distance between the centers of an enemy and a player
  # and if it's less the sum of their radii, there's been a collision
  # so invoke the callback
  checkCollision = (enemy, collidedCallback) ->
    radiusSum =  parseFloat(enemy.attr('r')) + parseFloat(player.attr('r'))
    xDiff = parseFloat(enemy.attr('cx')) - parseFloat(player.attr('cx'))
    yDiff = parseFloat(enemy.attr('cy')) - parseFloat(player.attr('cy'))

    separation = Math.sqrt( Math.pow(xDiff,2) + Math.pow(yDiff,2) )
    collidedCallback(enemy) if separation < radiusSum

  #If we have a collision, just reset the score
  onCollision = ->
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
