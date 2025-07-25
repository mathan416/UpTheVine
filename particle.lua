import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics

class("Particle").extends(gfx.sprite)

function Particle:init(x, y, size)
    size = size or 2

    -- Create a tiny filled square for the particle
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, size, size)
    gfx.popContext()

    self:setImage(img)
    self:setSize(size, size)
    self:moveTo(x, y)

    self.vx = math.random(-2, 2)
    self.vy = math.random(-4, -1)
    self.life = 0.5

    self:add()
end

-- Update Function
function Particle:update()
    self.vy =  self.vy +0.2
    self:moveBy(self.vx, self.vy)

    -- Sparkle effect
    if math.random() < 0.2 then
        self:setVisible(not self:isVisible())
    end

    self.life = self.life -  (1 / 30)
    if self.life <= 0 then
        self:remove()
    end
end