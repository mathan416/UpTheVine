import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "constants"

local gfx = playdate.graphics

class("Platform").extends(gfx.sprite)

-- Constructor
function Platform:init(x, y, width, height)
    self.width = width
    self.height = height

    self:setGroups({ kCollisionGroupPlatform })
    self:setCollidesWithGroups({ kCollisionGroupPlayer })
    self:setUpdatesEnabled(true)
    self.collisionType = kCollisionGroupPlatform

    self:refresh()
    self:setCollideRect(0, 0, width, height)
    self:moveTo(x, y)

    self:add()
end

-- Refresh
function Platform:refresh()
    local image = gfx.image.new(self.width, self.height)
    gfx.pushContext(image)
    gfx.setColor(gfx.kColorBlack)
    --gfx.fillRect(0, 0, self.width, self.height)
    gfx.popContext()

    self:setImage(image)
    self:setCollideRect(0, 0, self.width, self.height)
end