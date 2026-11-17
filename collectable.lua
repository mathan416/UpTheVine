import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"

class("Collectable").extends(playdate.graphics.sprite)

local gfx = playdate.graphics
local collectableTable = gfx.imagetable.new("images/collectable") -- from collectable-table-16-16.png
assert(collectableTable, "Missing images/collectable image table!")

-- Global collectibles tracking table
collectibles = collectibles or {}

-- Constructor
function Collectable:init(x, y)
    -- Load image table
    local imageTable = collectableTable
    assert(imageTable, "Missing images/collectable image table!")
    
    -- Set up animation (optional - animates through all frames)
    self.animation = gfx.animation.loop.new(150, imageTable, true)
    self:setImage(self.animation:image())
    
    local w, h = self:getSize()
    self:setSize(w, h)
    self:setZIndex(50)

    -- No collide rect; player can overlap freely
    self:moveTo(x, y)
    self:add()

    -- Add self to global collectibles table
    table.insert(collectibles, self)
end

-- Update for animation
function Collectable:update()
    self:setImage(self.animation:image())
end

-- Destructor
function Collectable:remove()
    -- Ensure proper cleanup from global collectibles table when removed
    for i = #collectibles, 1, -1 do
        if collectibles[i] == self then
            table.remove(collectibles, i)
            break
        end
    end
    playdate.graphics.sprite.remove(self)
end