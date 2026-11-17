import "CoreLibs/graphics"
import "CoreLibs/animation"
import "constants"
import "platform"

local gfx = playdate.graphics
local enemyTable = gfx.imagetable.new("images/vine_enemy")
assert(enemyTable)
class("VineEnemy").extends(gfx.sprite)

-- Constructor
function VineEnemy:init(vine, speed)
    VineEnemy.super.init(self)
    self.vine = vine
    self.speed = speed
    self.direction = 1

    -- Get image
    self.images = enemyTable
    assert(self.images, "vine_enemy image table failed to load")
    self.animation = gfx.animation.loop.new(500, self.images, true)
    self:setImage(self.animation:image())
    self:setSize(self:getSize())
    self:moveTo(vine.x, vine.y)

    -- Set collision type
    self.collisionType = kCollisionGroupEnemy
    self:setCollideRect(0, 0, self:getSize())
    self:setGroups({ kCollisionGroupEnemy })
    self:setCollidesWithGroups({ kCollisionGroupPlayer })
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

    self:setZIndex(100)
    self:add()
end

-- Updaste
function VineEnemy:update()
    -- Animate
    self:setImage(self.animation:image())

    -- Get the dimensions of the vine and position of Vine Enemy
    local topY = self.vine.y - self.vine.height / 2
    local bottomY = self.vine.y + self.vine.height / 2
    local newY = self.y + self.speed * self.direction

    -- Reversing logic
    if newY < topY then
        newY = topY
        self.direction = 1
    elseif newY > bottomY then
        newY = bottomY
        self.direction = -1
    end

    -- Move
    self:moveTo(self.vine.x, newY)

    -- If we hit a platform, head back up. Always set -1 rather than toggling:
    -- the enemy can overlap the platform for several frames, and toggling
    -- each frame would trap it jittering at the bottom of the vine.
    for _, plt in ipairs(gfx.sprite.getAllSprites()) do
        if plt:isa(Platform) and self:boundsOverlap(plt) then
            self.direction = -1
            break
        end
    end
end

-- check if bounds overlap
function VineEnemy:boundsOverlap(other)
    local ax, ay, aw, ah = self:getBounds()
    local bx, by, bw, bh = other:getBounds()
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end