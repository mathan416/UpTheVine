import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "constants"
import "player"
import "level"

local gfx = playdate.graphics


GameState = {
    score = 0,
    lives = 3,
    gamelevel = 1,
    pendingGameOver = false,
    state = "splash",
    backgroundSet = false
}

-- Some dimensions
w, h = playdate.display.getSize()
local scoreLabelW = gfx.getTextSize("Score:")
local livesLabelW = gfx.getTextSize("Lives:")
local levelLabelW = gfx.getTextSize("Level:")

-- Images
local backgroundImage = gfx.image.new("images/background")
assert(backgroundImage, "Background image failed to load!")
local gameplayBackground = gfx.image.new("images/background_playing")
assert(gameplayBackground, "Gameplay background failed to load!")
local gameoverBackground = gfx.image.new("images/gameover")
assert(gameoverBackground, "Gameplay background failed to load!")

-- Prepare the level and player
level = Level()
player = Player(200, 120)

-- Randomness
math.randomseed(playdate.getSecondsSinceEpoch())

-- Fonts and Text functions
local boldFont = gfx.font.new("Asheville-Sans-14-Bold")
local normalFont = gfx.getSystemFont()

local function drawShadowedText(text, x, y)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText(text, x + 1, y + 1)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawText(text, x, y)
end

local function drawLabelWithBackground(label, value, x, y)
    -- Background box
    --gfx.setColor(gfx.kColorWhite)
    --gfx.fillRect(x - 2, y - 2, 80, 18)  -- Adjust width as needed

    -- Text on top
    gfx.setFont(boldFont)
    drawShadowedText(label, x, y)
    gfx.setFont(normalFont)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawText(value, x + gfx.getTextSize(label) + 5, y+1)
end

-- Reset Game
local function resetGame()
    if DEBUG_MODE then print("→ resetGame() called") end
    playdate.graphics.sprite.removeAll()
    level = Level()
    player = Player(200, 120)
    GameState.score = 0
    GameState.lives = 3
    GameState.gamelevel = 1
end

-- Optional: centralize persistence
local function saveGame()
    -- TODO: write your save data (high score, progress, etc.)
    -- playdate.datastore.write({ highScore = ... }, "your_save")
end

-- Call when you want to purge scene objects and timers
local function cleanupScene()
    -- Stop/clear timers
    if playdate.timer.allTimers then
        for _, t in ipairs(playdate.timer.allTimers()) do
            if t and t.remove then t:remove() end
        end
    end

    -- Remove all sprites
    playdate.graphics.sprite.removeAll()

    -- Release background callback
    gfx.sprite.setBackgroundDrawingCallback(nil)

    -- Stop any audio (guarded)
    if sfx then
        for _, syn in pairs(sfx) do
            if syn and syn.stop then syn:stop() end
        end
    end
    if musicPlayer and musicPlayer.stop then musicPlayer:stop() end
end

-- Game Update Function
function playdate.update()
    -- Initialize
    gfx.clear()

    -- Timer
    playdate.timer.updateTimers()
    if DEBUG_MODE then print("DEBUG: GameState.state: "..GameState.state) end

    -- Loading
        --if allImagesProcessed == false then
            -- process images
            --for i = 1, #images do
                -- some time-consuming process…
            --    processImage( images[i] )
                -- draw a progress bar
            --    local progressPercentage = i / #images
            --    playdate.graphics.fillRect( 100, 20, 200*progressPercentage, 40 )
                -- yield to the OS, giving it a chance to update the screen
            --    coroutine.yield()
                -- execution will resume here when the OS calls coroutine.resume()
            --end
            --allImagesProcessed = true
        --end


    -- Game States
    -- Splash Screen
    if GameState.state == "splash" then
        GameState.pendingGameOver = false

        -- Set Background Refresh Logic and Background
        if GameState.backgroundSet then  
            gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(x, y, w, h)
            end)
            GameState.backgroundSet = false
        end

        backgroundImage:draw(0, 0)
        gfx.setFont(boldFont)

        -- Start Game on button A
        if playdate.buttonJustPressed(playdate.kButtonA) then
            GameState.state = "playing"
        end

    -- Playing Game
    elseif GameState.state == "playing" then
        -- Set Bakcground Refresh Logic
        if not GameState.backgroundSet then 
            gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
                if gameplayBackground then
                gameplayBackground:draw(0, 0) -- Draw the image at the top-left corner
                end
            end)
           GameState.backgroundSet = true
        end

        -- Load Game, Render Level
        --loadSavedGame()
        playdate.graphics.sprite.redrawBackground()
        level:update()
        gfx.sprite.update()

        -- Set Score, Level and Lives 
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 10, 400, 17)
        drawLabelWithBackground("Score:", string.format("%05d", GameState.score), 10, 10)
        drawLabelWithBackground("Level:", tostring(GameState.gamelevel), 175, 10)
        drawLabelWithBackground("Lives:", tostring(GameState.lives), 340, 10)

        -- Initiate Game Over
        if GameState.lives <= 0 and not GameState.pendingGameOver then
            GameState.pendingGameOver = true
            playdate.timer.performAfterDelay(1000, function()
                GameState.state = "gameover"
            end)
        end

    -- Game Over
    elseif GameState.state == "gameover" then
        
        -- Set Bakcground Refresh Logic and Background
        if GameState.backgroundSet then  
            gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(x, y, w, h)
            end)
            GameState.backgroundSet = false
        end
        gameoverBackground:draw(0, 0)

        -- Save High Score
        -- if GameState.score > gameData.highScore then
        --    gameData.highScore = GameState.score
        --    saveGame() 
        -- end

        -- Pause 3 seconds and Initiate Splash
        if DEBUG_MODE then print("DEBUG: pendingGameOver: ",GameState.pendingGameOver) end
        if GameState.pendingGameOver == true then
            GameState.pendingGameOver = false
            playdate.timer.performAfterDelay(3000, function()
                GameState.state = "splash"
                cleanupScene()     -- optional: clear sprites/timers/background first
                resetGame()
            end)
            -- Block for 3 seconds
            --playdate.wait(3000)
            --playdate.display.flush()
            --GameState.state = "splash"
            --resetGame()
        end
    end

    if DEBUG_MODE then
        gfx.setColor(gfx.kColorBlack)
        playdate.drawFPS(200, 120)
    end
end

-- Helpers
local function stopAllAudio()
    if sfx then
        for _, syn in pairs(sfx) do
            if syn and syn.stop then syn:stop() end
        end
    end
    if musicPlayer and musicPlayer.stop then musicPlayer:stop() end
end

-- Called when user opens System Menu (pause) or app is backgrounded
function playdate.gameWillPause()
    saveGame()
    -- optional:
    -- stopAllAudio()
end

-- Called when device is about to sleep (low power, lid close, etc.)
function playdate.deviceWillSleep()
    saveGame()
    stopAllAudio() -- nice to be polite
end

-- Called when user exits the game
function playdate.gameWillTerminate()
    saveGame()
    cleanupScene() -- remove timers/sprites, clear bg callbacks, stop audio
end

-- Called when resuming from pause (System Menu closed)
function playdate.gameWillResume()
    -- restore audio, resume timers if needed
    -- musicPlayer:play() or re-init background callback
end

-- Called when waking from device sleep
function playdate.deviceDidWake()
    -- same idea as above, but device-level
    -- refresh background image if you were using setBackgroundDrawingCallback
end