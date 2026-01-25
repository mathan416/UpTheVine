import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

class("Particle").extends(playdate.graphics.sprite)

local gfx = playdate.graphics

-- =========================================================
-- Shared particle images (allocated ONCE, reused forever)
-- =========================================================
local PARTICLE_IMAGES = nil

local function buildParticleImages()
    if PARTICLE_IMAGES then return end

    -- Make a few sizes so sparkle has variety (all transparent background)
    PARTICLE_IMAGES = {}

    local function makeDot(w, h)
        local img = gfx.image.new(w, h, gfx.kColorClear)
        gfx.pushContext(img)
            gfx.setColor(gfx.kColorBlack)      -- <- visible on dark backgrounds
            gfx.fillRect(0, 0, w, h)
        gfx.popContext()
        return img
    end

    PARTICLE_IMAGES[1] = makeDot(2, 2)
    PARTICLE_IMAGES[2] = makeDot(1, 1)
    PARTICLE_IMAGES[3] = makeDot(3, 3)
end

-- Constructor
function Particle:init(x, y, size)
    buildParticleImages()

    -- Pick a shared image (optionally influenced by "size")
    local imgIndex = 1
    if size == 1 then
        imgIndex = 2
    elseif size and size >= 3 then
        imgIndex = 3
    else
        imgIndex = math.random(1, #PARTICLE_IMAGES)
    end

    self:setImage(PARTICLE_IMAGES[imgIndex])
    self:moveTo(x, y)

    -- Physics
    self.vx = math.random(-20, 20) / 10
    self.vy = math.random(-30, -10) / 10

    self.life = 0.5
    self:add()
end

-- Update Function
function Particle:update()
    self.vy = self.vy + 0.2
    self:moveBy(self.vx, self.vy)

    -- Sparkle effect
    if math.random() < 0.2 then
        self:setVisible(not self:isVisible())
    end

    self.life = self.life - (1 / 30)
    if self.life <= 0 then
        self:remove()
    end
end