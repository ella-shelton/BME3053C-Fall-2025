-- Simple Pong in LÖVE (Love2D)
-- Controls:
--   Left paddle: W/S
--   Right paddle: Up/Down
--   Space: serve/start, P: pause, R: reset, Esc: quit

local width, height
local paddleW, paddleH, paddleSpeed
local leftPaddle, rightPaddle
local ball
local leftScore, rightScore
local gameState -- 'serve', 'play', 'pause'
local servingPlayer -- 'left' or 'right'

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

local function randomColor()
  local r = love.math.random(40, 100) / 100
  local g = love.math.random(40, 100) / 100
  local b = love.math.random(40, 100) / 100
  return r, g, b
end

local function resetBall(direction)
  ball.x = width / 2 - ball.s / 2
  ball.y = height / 2 - ball.s / 2
  local angle = math.rad(love.math.random(20, 45))
  local speed = ball.baseSpeed
  local dx = math.cos(angle) * speed
  local dy = math.sin(angle) * speed * (love.math.random(0, 1) == 0 and -1 or 1)
  ball.dx = (direction == 'left') and -dx or dx
  ball.dy = dy
end

local function resetGame()
  leftScore, rightScore = 0, 0
  servingPlayer = (love.math.random(0, 1) == 0) and 'left' or 'right'
  resetBall(servingPlayer)
  gameState = 'serve'
end

function love.load()
  love.window.setTitle("Pong - Codespaces + LÖVE")
  width, height = 800, 600
  love.window.setMode(width, height, { vsync = 1 })

  paddleW, paddleH = 12, 90
  paddleSpeed = 320

  leftPaddle = { x = 30, y = height/2 - paddleH/2, w = paddleW, h = paddleH }
  rightPaddle = { x = width - 30 - paddleW, y = height/2 - paddleH/2, w = paddleW, h = paddleH }
  leftPaddle.r, leftPaddle.g, leftPaddle.b = 1, 1, 1
  rightPaddle.r, rightPaddle.g, rightPaddle.b = 1, 1, 1

  ball = { x = 0, y = 0, s = 12, dx = 0, dy = 0, baseSpeed = 260, speedGain = 18 }
  ball.r, ball.g, ball.b = randomColor()

  love.math.setRandomSeed(os.time())
  resetGame()
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
  if key == 'p' and gameState ~= 'serve' then
    gameState = (gameState == 'pause') and 'play' or 'pause'
  end
  if key == 'r' then
    leftPaddle.y = height/2 - paddleH/2
    rightPaddle.y = height/2 - paddleH/2
    leftPaddle.r, leftPaddle.g, leftPaddle.b = 1, 1, 1
    rightPaddle.r, rightPaddle.g, rightPaddle.b = 1, 1, 1
    resetGame()
  end
  if key == 'space' then
    if gameState == 'serve' then
      gameState = 'play'
    elseif gameState == 'pause' then
      gameState = 'play'
    end
  end
end

function love.update(dt)
  if gameState == 'pause' then return end

  -- Left paddle controls (W/S)
  if love.keyboard.isDown('w') then
    leftPaddle.y = leftPaddle.y - paddleSpeed * dt
  elseif love.keyboard.isDown('s') then
    leftPaddle.y = leftPaddle.y + paddleSpeed * dt
  end
  leftPaddle.y = clamp(leftPaddle.y, 0, height - leftPaddle.h)

  -- Right paddle controls (Up/Down)
  if love.keyboard.isDown('up') then
    rightPaddle.y = rightPaddle.y - paddleSpeed * dt
  elseif love.keyboard.isDown('down') then
    rightPaddle.y = rightPaddle.y + paddleSpeed * dt
  end
  rightPaddle.y = clamp(rightPaddle.y, 0, height - rightPaddle.h)

  if gameState == 'serve' then
    -- Keep ball centered during serve; velocity is already set
    ball.x = ball.x + 0
    ball.y = ball.y + 0
    return
  end

  -- Move ball
  ball.x = ball.x + ball.dx * dt
  ball.y = ball.y + ball.dy * dt

  -- Collide top/bottom
  if ball.y <= 0 then
    ball.y = 0
    ball.dy = -ball.dy
    ball.r, ball.g, ball.b = randomColor()
  elseif ball.y + ball.s >= height then
    ball.y = height - ball.s
    ball.dy = -ball.dy
    ball.r, ball.g, ball.b = randomColor()
  end

  -- Collide paddles
  if aabb(ball.x, ball.y, ball.s, ball.s, leftPaddle.x, leftPaddle.y, leftPaddle.w, leftPaddle.h) then
    ball.x = leftPaddle.x + leftPaddle.w
    ball.dx = math.abs(ball.dx) + ball.speedGain
    local offset = (ball.y + ball.s/2) - (leftPaddle.y + leftPaddle.h/2)
    ball.dy = ball.dy + offset * 5 * dt
    ball.r, ball.g, ball.b = randomColor()
    leftPaddle.r, leftPaddle.g, leftPaddle.b = ball.r, ball.g, ball.b
  elseif aabb(ball.x, ball.y, ball.s, ball.s, rightPaddle.x, rightPaddle.y, rightPaddle.w, rightPaddle.h) then
    ball.x = rightPaddle.x - ball.s
    ball.dx = -math.abs(ball.dx) - ball.speedGain
    local offset = (ball.y + ball.s/2) - (rightPaddle.y + rightPaddle.h/2)
    ball.dy = ball.dy + offset * 5 * dt
    ball.r, ball.g, ball.b = randomColor()
    rightPaddle.r, rightPaddle.g, rightPaddle.b = ball.r, ball.g, ball.b
  end

  -- Score left/right sides
  if ball.x + ball.s < 0 then
    rightScore = rightScore + 1
    servingPlayer = 'left'
    resetBall(servingPlayer)
    gameState = 'serve'
  elseif ball.x > width then
    leftScore = leftScore + 1
    servingPlayer = 'right'
    resetBall(servingPlayer)
    gameState = 'serve'
  end
end

function love.draw()
  -- Background
  love.graphics.setColor(1, 1, 1)

  -- Center line
  love.graphics.setLineWidth(2)
  for y = 0, height, 20 do
    love.graphics.line(width/2, y, width/2, y + 10)
  end

  -- Scores
  love.graphics.print("PONG", width/2 - 20, 16)
  love.graphics.print(tostring(leftScore), width/2 - 60, 40)
  love.graphics.print(tostring(rightScore), width/2 + 48, 40)

  -- Paddles and ball
  love.graphics.setColor(leftPaddle.r, leftPaddle.g, leftPaddle.b)
  love.graphics.rectangle('fill', leftPaddle.x, leftPaddle.y, leftPaddle.w, leftPaddle.h)
  love.graphics.setColor(rightPaddle.r, rightPaddle.g, rightPaddle.b)
  love.graphics.rectangle('fill', rightPaddle.x, rightPaddle.y, rightPaddle.w, rightPaddle.h)
  love.graphics.setColor(ball.r, ball.g, ball.b)
  love.graphics.rectangle('fill', ball.x, ball.y, ball.s, ball.s)
  love.graphics.setColor(1, 1, 1)

  -- Instructions / state
  local infoY = height - 28
  if gameState == 'serve' then
    love.graphics.print("Press Space to Serve (" .. servingPlayer .. ")", width/2 - 90, infoY)
  elseif gameState == 'pause' then
    love.graphics.print("Paused (P to resume)", width/2 - 70, infoY)
  else
    love.graphics.print("W/S & Up/Down | P pause | R reset", width/2 - 140, infoY)
  end
end