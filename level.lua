import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "constants"
import "vine"
import "collectable"
import "platform"
import "vineenemy"
import "flyingenemy"

class("Level").extends()

-- Constructor
function Level:init()
    self.vines = {}
    self.platforms = {}
    self.usedVineSlots = {}
    self:buildLevel()
end

-- Create Level
function Level:buildLevel()
    self:spawnPlatforms()
    self:spawnInitialVines()
    self:spawnVineEnemies()
    self:spawnFlyingEnemies(w, h)
end

-- Spawn a single platform
function Level:spawnPlatforms()
    local p = Platform(200, 200, 400, 8)
    table.insert(self.platforms, p)
end

-- Spawn the first vine 
function Level:spawnInitialVines()
    local maxSlots = 15
    local platformTopY = 196
    local marginX = 50
    local numVines = 1

    local usableWidth = w - (2 * marginX) -- 300
    local slotWidth = usableWidth / maxSlots

    local xSlots = {}
    for i = 1, maxSlots do
        --xSlots[i] = (i - 0.5) * (w / maxSlots)
        xSlots[i] = marginX + (i - 0.5) * slotWidth
    end

    -- Build list of available slots
    local available = {}
    for i = 1, maxSlots do
        if not self.usedVineSlots[i] then
            table.insert(available, i)
        end
    end

    -- Abort if no slots available
    if #available == 0 then
        if DEBUG_MODE then print("No free slots for initial vine") end
        return
    end

    -- Pick a random slot and mark it used
    local slotIndex = available[math.random(1, #available)]
    self.usedVineSlots[slotIndex] = true

    -- Create and add vine
    local x = xSlots[slotIndex]
    local height = math.random(70, 100)
    local radius = math.random(3, 5)
    local vineBottomY = math.random(platformTopY - 50, platformTopY)
    local y = vineBottomY - height / 2

    local vine = Vine(x, y, height, radius)
    table.insert(self.vines, vine)

    -- Add collectables
    local count = math.random(1, 6)
    self:spawnCollectablesOnVine(vine, count)

end

-- Add a Vine Enemy to all vines 
function Level:spawnVineEnemies()
    for _, vine in ipairs(self.vines) do
        local speed = math.random(1, 10) / 10
        VineEnemy(vine, speed)
    end
end

-- Add a Flying Enemy
function Level:spawnFlyingEnemies(w, h)
    local usedYs = {}
    local topMargin = 30
    local maxEnemies = 2

    -- Iterate adding multiple enemies
    for _ = 1, maxEnemies do
        local y = math.random(topMargin, h / 1.5)
        local tooClose = false
        for _, uy in ipairs(usedYs) do
            if math.abs(uy - y) < 16 then
                tooClose = true
                break
            end
        end
        if not tooClose then
            table.insert(usedYs, y)
            local x = math.random(0, w)
            local speed = math.random(1, 3)
            local dir = math.random() < 0.5 and "left" or "right"
            FlyingEnemy(x, y, speed, dir)
        end
    end
end

-- Add Collectables to a Vine 
function Level:spawnCollectablesOnVine(vine, count)
    local vineX = vine.x
    local segH = 16
    local vineTopY = vine.y - vine.height / 2
    local numSeg = math.floor(vine.height / segH)

    local segmentCenters = {}
    for i = 0, numSeg - 2 do
        segmentCenters[#segmentCenters + 1] = vineTopY + i * segH + segH / 2
    end

    for i = #segmentCenters, 2, -1 do
        local j = math.random(1, i)
        segmentCenters[i], segmentCenters[j] = segmentCenters[j], segmentCenters[i]
    end

    for i = 1, math.min(count, #segmentCenters) do
        Collectable(vineX, segmentCenters[i])
    end
end

-- Update function called from main.lua
function Level:update()
    local anyCollectables = false

    -- Check if we have collectables
    for _, sprite in ipairs(playdate.graphics.sprite.getAllSprites()) do
        if sprite:isa(Collectable) then
            anyCollectables = true
            break
        end
    end

    -- Trigger additiona; vine and spawn collectables 
    -- Once we collect all Collectables
    if not anyCollectables then
        if not GameState.pendingGameOver then
            if #self.vines < 23 then
                self:spawnAdditionalVine()
            end

            for _, vine in ipairs(self.vines) do
                self:spawnCollectablesOnVine(vine, vine.segmentCount or 4)
            end

            GameState.lives = 3
            GameState.gamelevel += 1
        end
    end
end

function Level:clear()
    for _, vine in ipairs(self.vines) do vine:remove() end
    for _, plat in ipairs(self.platforms) do plat:remove() end
    playdate.graphics.sprite.removeAll()
    self.vines = {}
    self.platforms = {}
end

function Level:renderVinePlatforms()
    for _, spr in ipairs(playdate.graphics.sprite.getAllSprites()) do
        if spr:isa(Vine) or spr:isa(Platform) then
            spr:refresh()
        end
    end
end

function Level:spawnAdditionalVine()
    local maxSlots = 15
    local platformTopY = 196

    local marginX = 50
    local usableWidth = w - (2 * marginX) -- 300
    local slotWidth = usableWidth / maxSlots 

    local xSlots = {}
    for i = 1, maxSlots do
        --xSlots[i] = (i - 0.5) * (w / maxSlots)
        xSlots[i] = marginX + (i - 0.5) * slotWidth
    end

    -- Build list of available slots
    local available = {}
    for i = 1, maxSlots do
        if not self.usedVineSlots[i] then
            table.insert(available, i)
        end
    end

     -- Abort if no slots available
    if #available == 0 then
        if DEBUG_MODE then print("All vine slots occupied, no vine spawned") end
        return
    end

    -- Pick a random slot and mark it used
    local slotIndex = available[math.random(1, #available)]
    self.usedVineSlots[slotIndex] = true

    -- Create and add vine
    local x = xSlots[slotIndex]
    local height = math.random(80, 120)
    local radius = 3
    local vineBottomY = math.random(platformTopY - 50, platformTopY)
    local y = vineBottomY - height / 2

    local vine = Vine(x, y, height, radius)
    table.insert(self.vines, vine)

    -- Add a Vine Enemy
    local vineEnemySpeed = math.random(1, 10) / 10
    VineEnemy(vine, vineEnemySpeed)

    -- Add collectables
    local count = math.random(1, 6)
    self:spawnCollectablesOnVine(vine, count)
end