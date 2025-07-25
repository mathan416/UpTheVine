import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "particle"
import "platform"
import "constants"

class("Player").extends(playdate.graphics.sprite)

local gfx = playdate.graphics

-- Constructor
function Player:init(x, y)
    -- Setup player image and collision type
    self.image = gfx.image.new("images/player")
    self:setImage(self.image)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, self:getSize())
    self:setGroups({ kCollisionGroupPlayer })
    self:setCollidesWithGroups({ kCollisionGroupEnemy, kCollisionGroupPlatform })
    self.collisionType = kCollisionGroupPlayer
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
    self:add()
    self.invincible = false

    -- Gravity physics
    self.gravity = 0.3
    self.bounceDamping = 0.6
    self.minBounceVelocity = 0.4

    -- Placement
    self.vx = 0
    self.vy = 0

    -- Speed dynamics
    self.speed = 2
    self.jumpStrength = -6
    self.shortHopStrength = -6
    self.groundPoundSpeed = 5

    -- Status
    self.onGround = false
    self.isOnVine = false
    self.preventVineGrab = false
    self.airborneFromJump = nil
    self.bounceActive = true
    self.pendingVineAttach = false
end

-- Update function
function Player:update()
    self.onGround = false

    -- We are in the air, let gavity take hold
    if not self.onGround and not self.isOnVine then
        self.vy = self.vy + self.gravity
    end

    -- Move the sprite 
    local tentativeY = self.y + self.vy
    local _, actualY, collisions, length = self:moveWithCollisions(self.x, tentativeY)
    local resolvedY = actualY

    -- Collision checking
    for i = 1, length do
        local col = collisions[i]
        local other = col.other

        -- If we hit a Flying Enemy
        if other:isa(FlyingEnemy) and not self.invincible then
            self:handleHit()
            resolvedY = actualY
            break
        end

        -- If we hit a Vine Enemy
        if other:isa(VineEnemy) and not self.invincible then
            self:handleHit()
            resolvedY = actualY
            break
        end

        -- Are we on the platform
        if other.collisionType == kCollisionGroupPlatform and self.vy > 0 then
            -- Trigger Game over if we die while falling
            if GameState.pendingGameOver then
                playdate.wait(1000)
                playdate.display.flush()
                GameState.state = "gameover"
                -- GameState.pendingGameOver = false
                break
            end

            -- Bounce handling
            if self.bounceActive and math.abs(self.vy) > self.minBounceVelocity then
                self.vy = -self.vy * self.bounceDamping
                self:spawnBounceParticles()
            else
                self.vy = 0
                self.bounceActive = false
                self.preventVineGrab = false
            end

            -- We are on the ground
            self.onGround = true
            resolvedY = other.y - other.height / 2 - self.height / 2
            break
        end
    end

    -- Call andle input and then move 
    self:handleInput()

    -- Move player if on the edge
    local nextX = math.max(self.width / 2, math.min(400 - self.width / 2, self.x + self.vx))
    self:moveTo(nextX, resolvedY)

    -- If we're not on the ground, not on a vine, and not airport, ensure airbone from a jump 
    -- Is nil - we might be bouncing or falling
    if not self.onGround and not self.isOnVine and self.airborneFromJump == nil then
        self.airborneFromJump = false
    end

    -- Allow a short jump onto a vine
    if self.pendingVineAttach and self.vy > 0 then
        for _, vine in ipairs(gfx.sprite.getAllSprites()) do
            if vine:isa(Vine) and self:boundsOverlap(vine) then
                self.isOnVine = true
                self.vy = 0
                self.onGround = false
                self.bounceActive = false
                self.pendingVineAttach = false
                break
            end
        end
    end

    -- Check for collectables and vines
    self:checkCollectables()
    self:checkVine()

    self.vx = 0
end

-- If we're hit, drop life, display particles, breifly invincible
function Player:handleHit()
    GameState.lives = math.max(GameState.lives - 1, 0)
    self:spawnHitParticles()
    self.invincible = true
    playdate.timer.performAfterDelay(1000, function()
        self.invincible = false
    end)
end

-- What happens with the controler
function Player:handleInput()
    -- Move left or right
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        self.vx = -self.speed
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        self.vx = self.speed
    end

    -- If we're on a vine
    if self.isOnVine then
        -- Allow up and down on the vine, otherwise stop
        if playdate.buttonIsPressed(playdate.kButtonUp) then
            self.vy = -self.speed
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then
            self.vy = self.speed
        else
            self.vy = 0
        end

        -- If B, then jump off the vine via ground pound
        if playdate.buttonJustPressed(playdate.kButtonB) then
            self.isOnVine = false
            self:performGroundPound()
        end
    end

    -- If A, then allowjump
    if playdate.buttonJustPressed(playdate.kButtonA) then
        local overlappingVine = false
        
        -- Check if we're jumping on a vine
        for _, vine in ipairs(gfx.sprite.getAllSprites()) do
            if vine:isa(Vine) and self:boundsOverlap(vine) then
                overlappingVine = true
                break
            end
        end

        -- Short hop
        if overlappingVine then
            self.vy = self.shortHopStrength
            self.isOnVine = false
            self.onGround = false
            self.bounceActive = false
            self.pendingVineAttach = true
        -- Big jump off vine
        elseif self.isOnVine then
            self.vy = self.jumpStrength
            self.isOnVine = false
            self.airborneFromJump = true
        -- Regular jump from ground
        elseif self.onGround then
            self.vy = self.jumpStrength
            self.isOnVine = false
            self.airborneFromJump = true
        end
    end

    -- If B, Ground Pound
    if playdate.buttonJustPressed(playdate.kButtonB) and not self.onGround then
        if not self.isOnVine then
            self:performGroundPound()
        end
    end
end


-- Ground Pound
function Player:performGroundPound()
    self.vy = self.groundPoundSpeed
    self.bounceActive = true
    self.isOnVine = false
    self.airborneFromJump = false
    self.preventVineGrab = true
end

-- Check if we're close to a vine
function Player:checkVine()
    local foundVine = false
    if self.pendingVineAttach then return end

    -- Set variables if we're on a vine
    if not self.preventVineGrab then
        for _, vine in ipairs(gfx.sprite.getAllSprites()) do
            if vine:isa(Vine) and self:boundsOverlap(vine) then
                if not self.isOnVine then
                    self.isOnVine = true
                    self.vy = 0
                    self.onGround = false
                    self.bounceActive = false
                end
                foundVine = true
                break
            end
        end
    end

    -- Reset if not on a vine
    if self.isOnVine and not foundVine then
        self.isOnVine = false
        self.bounceActive = true
    end
end

-- Check if we're touch ing a collectable
function Player:checkCollectables()
    for _, sprite in ipairs(gfx.sprite.getAllSprites()) do
        if sprite:isa(Collectable) and self:boundsOverlap(sprite) then
            sprite:remove()
            GameState.score = GameState.score + 100
        end
    end
end

-- Helper function for overlapping checks
function Player:boundsOverlap(other)
    local ax, ay, aw, ah = self:getBounds()
    local bx, by, bw, bh = other:getBounds()
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- When we detach from a vine, set variables
function Player:detachFromVine()
    self.isOnVine = false
    self.bounceActive = true
    self.preventVineGrab = true
    self.airborneFromJump = false
    self.vy = self.gravity * 2
end

-- When we bounce, particle effects!
function Player:spawnBounceParticles()
    local px = self.x
    local py = self.y + self.height / 2
    for i = 1, 10 do
        Particle(px + math.random(-4, 4), py, 2)
    end
end

-- When we get hit, particle effects!
function Player:spawnHitParticles()
    local px = self.x
    local py = self.y
    for i = 1, 8 do
        Particle(px + math.random(-4, 4), py + math.random(-4, 4), 2)
    end
end