import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "constants"

local gfx = playdate.graphics

if not math.clamp then
    function math.clamp(val, lower, upper)
        return math.min(math.max(val, lower), upper)
    end
end

class("FlyingEnemy").extends(gfx.sprite)

-- Constructor
function FlyingEnemy:init(startX, y, speed, dir)
    FlyingEnemy.super.init(self)

    self.speed = speed * (dir == "left" and -1 or 1)

    self.imgTable = gfx.imagetable.new("images/flying_enemy")
    assert(self.imgTable, "Missing flying_enemy image table!")

    -- Animation
    self.anim = gfx.animation.loop.new(250, self.imgTable, true)
    self:setImage(self.anim:image())
    self:setSize(self:getSize())
    self:moveTo(startX, y)

    -- Set Collission behaviour
    self.collisionType = kCollisionGroupEnemy
    self:setCollideRect(0, 0, self:getSize())
    self:setGroups({ kCollisionGroupEnemy })
    self:setCollidesWithGroups({ kCollisionGroupPlayer })
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
    self:add()
end

-- Update
function FlyingEnemy:update()
    self:setImage(self.anim:image())

    -- Move only in x direction
    local newX = self.x + self.speed

    -- If we hit the edge of the screen choose whether we wrap or reverse
 
    if newX < -self.width/2 or newX > w + self.width/2 then
        if math.random() < 0.5 then
            -- Ternary condition then else
            newX = (newX < 0) and (w + self.width/2) or (-self.width/2)
        else
            -- Ternary condition then else
            self.speed = -self.speed
            newX = math.clamp(newX, -self.width/2, w + self.width/2)
        end
    end

    self:moveTo(newX, self.y)
end