import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "constants"

local gfx = playdate.graphics

class("Vine").extends(gfx.sprite)

-- Constructor
function Vine:init(x, y, height, radius)
    self.height = height or 100
    self.radius = radius or 3
    self.segmentHeight = 16

    self:refresh()
    self:moveTo(x, y)

    self:setUpdatesEnabled(true)
    self.collisionType = kCollisionGroupVine

    self:add()
end

-- Refresh
function Vine:refresh()
    -- Draw the line
    local vineWidth = self.radius * 2 + 2
    local vineImage = gfx.image.new(vineWidth, self.height)
    gfx.pushContext(vineImage)

    -- Draw the waves
    local centerX = vineWidth / 2
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(centerX, 0, centerX, self.height)

    for i = 0, self.height, 2 do
        local angle = i * 0.2
        local offset = math.sin(angle) * self.radius
        gfx.drawPixel(centerX + offset, i)
        gfx.drawPixel(centerX - offset, i)
    end

    gfx.popContext()
    self:setImage(vineImage)
end

-- Get the top
function Vine:getTopY()
    return self.y - self.height / 2
end

-- Get the bottom
function Vine:getBottomY()
    return self.y + self.height / 2
end

-- Figure how many 16px segments there are
function Vine:getNumSegments()
    return math.floor(self.height / self.segmentHeight)
end

-- Centerpoint
function Vine:getSegmentCenterY(index)
    return self:getTopY() + (index * self.segmentHeight) + self.segmentHeight / 2
end