import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

class("Collectable").extends(playdate.graphics.sprite)

local gfx = playdate.graphics

-- Global collectibles tracking table
collectibles = collectibles or {}

-- Constructor
function Collectable:init(x, y)
    local image = gfx.image.new("images/collectable")
    assert(image, "Missing collectable.png image!")
    self:setImage(image)

    local w, h = image:getSize()
    self:setSize(w, h)
    self:setZIndex(50)

    -- No collide rect; player can overlap freely
    self:moveTo(x, y)
    self:add()

    -- Add self to global collectibles table
    table.insert(collectibles, self)
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