import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "constants"
import "player"
import "level"
import "highscore"
import "sound"

local gfx = playdate.graphics

if _G.__UPTHEVINE_LOADED then
    return
end
_G.__UPTHEVINE_LOADED = true

GameState = {
    score = 0,
    lives = 3,
    gamelevel = 1,
    pendingGameOver = false,
    gameOverFrames = 0,
    state = "splash",
    backgroundSet = false,
    returnToState = nil,
    titleMusicPlayed = false -- no longer used for MP3, but keeping for now
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
local lastState = nil
level = Level()
player = Player(200, 120)

-- Load high score
loadSavedGame()

-- Randomness
math.randomseed(playdate.getSecondsSinceEpoch())

-- Fonts
local boldFont = gfx.font.new("Asheville-Sans-14-Bold")
local normalFont = gfx.getSystemFont()

local function drawShadowedText(text, x, y)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText(text, x + 1, y + 1)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawText(text, x, y)
end

local function drawLabelWithBackground(label, value, x, y)
    gfx.setFont(boldFont)
    drawShadowedText(label, x, y)
    gfx.setFont(normalFont)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawText(value, x + gfx.getTextSize(label) + 5, y + 1)
end

-- ✅ Title music controller (single source of truth)
local function ensureTitleMusic()
    if Sound.isMuted() then
        -- if muted, make sure it stops
        Sound.stopTitleMusicFile()
        return
    end

    if GameState.state == "splash" or GameState.state == "credits" then
        Sound.playTitleMusicFile()   -- safe to call repeatedly (it checks isPlaying)
    else
        Sound.stopTitleMusicFile()
    end
end

-- Setup System Menu
local menu = playdate.getSystemMenu()

menu:addCheckmarkMenuItem("Mute", Sound.isMuted(), function(value)
    Sound.setMuted(value)
    -- No need to touch titleMusicPlayed anymore.
    -- ensureTitleMusic() will handle play/stop based on state + mute.
end)

local creditsMenuItem = menu:addMenuItem("Credits", function()
    -- If we're already in credits, don't clobber returnToState
    if GameState.state ~= "credits" then
        GameState.returnToState = GameState.state
    end

    GameState.backgroundSet = false
    GameState.state = "credits"
end)

-- Reset Game
local function resetGame()
    if DEBUG_MODE then print("→ resetGame() called") end
    playdate.graphics.sprite.removeAll()
    level = Level()
    player = Player(200, 120)
    GameState.score = 0
    GameState.lives = 3
    GameState.gamelevel = 1
    GameState.titleMusicPlayed = false -- harmless leftover
end

-- Call when you want to purge scene objects and timers
local function cleanupScene()
    if playdate.timer.allTimers then
        for _, t in ipairs(playdate.timer.allTimers()) do
            if t and t.remove then t:remove() end
        end
    end

    playdate.graphics.sprite.removeAll()
    gfx.sprite.setBackgroundDrawingCallback(nil)

    if Sound and Sound.stopAll then
        Sound.stopAll()
    end
end

-- Game Update Function
function playdate.update()
    gfx.clear()
    playdate.timer.updateTimers()

    -- ✅ always enforce correct music for current state
    ensureTitleMusic()

    if DEBUG_MODE then print("DEBUG: GameState.state: "..GameState.state) end

    -- Splash Screen
    if GameState.state == "splash" then
        GameState.pendingGameOver = false

        if GameState.backgroundSet then
            gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(x, y, w, h)
            end)
            GameState.backgroundSet = false
        end

        backgroundImage:draw(0, 0)
        gfx.setFont(boldFont)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            -- ensureTitleMusic will stop it once we switch state
            GameState.state = "playing"
        end

    -- Playing Game
    elseif GameState.state == "playing" then
        if not GameState.backgroundSet then
            gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
                if gameplayBackground then
                    gameplayBackground:draw(0, 0)
                end
            end)
            GameState.backgroundSet = true
        end

        playdate.graphics.sprite.redrawBackground()

        if not GameState.pendingGameOver then
            level:update()
        end
        gfx.sprite.update()

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 10, 400, 17)
        drawLabelWithBackground("Score:", string.format("%05d", GameState.score), 10, 10)
        drawLabelWithBackground("Level:", tostring(GameState.gamelevel), 175, 10)
        drawLabelWithBackground("Lives:", tostring(GameState.lives), 340, 10)

        if GameState.lives <= 0 and not GameState.pendingGameOver then
            GameState.pendingGameOver = true
            GameState.gameOverFrames = 0
            Sound.playGameOverSound()
        end

        if GameState.pendingGameOver then
            GameState.gameOverFrames += 1
            if GameState.gameOverFrames >= 20 then
                playdate.wait(500)
                GameState.state = "gameover"
                GameState.gameOverFrames = 0
            end
        end

    -- Game Over
    elseif GameState.state == "gameover" then
        gameoverBackground:draw(0, 0)

        if GameState.score > getHighScore() then
            saveGame(GameState.score)
        end

        gfx.setFont(boldFont)
        local scoreText = "Score: " .. string.format("%05d", GameState.score)
        local highScoreText = "High Score: " .. string.format("%05d", getHighScore())

        local scoreWidth = gfx.getTextSize(scoreText)
        local highScoreWidth = gfx.getTextSize(highScoreText)

        drawShadowedText(scoreText, (w - scoreWidth) / 3, 100)
        drawShadowedText(highScoreText, (w - highScoreWidth) / 3, 120)

        if GameState.pendingGameOver == true then
            GameState.pendingGameOver = false
            playdate.timer.performAfterDelay(3000, function()
                GameState.state = "splash"
                cleanupScene()
                resetGame()
            end)
        end

    -- Credits Screen
    elseif GameState.state == "credits" then
        gameplayBackground:draw(0, 0)

        local startY = 15
        local lineHeight = 16
        local leftColumnX = 80
        local rightColumnX = 220

        gfx.setFont(boldFont)
        local titleText = "UP THE VINE"
        local titleWidth = gfx.getTextSize(titleText)
        drawShadowedText(titleText, (w - titleWidth) / 2, startY)

        local currentY = startY + lineHeight + 3

        gfx.setFont(normalFont)
        drawShadowedText("Created by:", leftColumnX, currentY)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawText("Iain Bennett", rightColumnX, currentY)
        currentY += lineHeight * 2

        drawShadowedText("Programming:", leftColumnX, currentY)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawText("Iain Bennett", rightColumnX, currentY)
        currentY += lineHeight * 2

        drawShadowedText("Art & Design:", leftColumnX, currentY)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawText("Chris Hagen", rightColumnX, currentY)
        currentY += lineHeight
        gfx.drawText("Iain Bennett", rightColumnX, currentY)
        currentY += lineHeight * 2

        drawShadowedText("Music & Sound:", leftColumnX, currentY)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawText("Iain Bennett", rightColumnX, currentY)
        currentY += lineHeight
        gfx.drawText("Aaron Sheppard", rightColumnX, currentY)
        currentY += lineHeight + 6

        gfx.setFont(boldFont)
        local footerText = "Press A to Return"
        local footerWidth = gfx.getTextSize(footerText)
        drawShadowedText(footerText, (w - footerWidth) / 2, currentY)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            GameState.state = GameState.returnToState or "splash"
            GameState.backgroundSet = false
        end
    end

    if not _gcFrame then _gcFrame = 0 end
    _gcFrame += 1
    if _gcFrame % 60 == 0 then
         if DEBUG_MODE then
            print("GC KB:", collectgarbage("count"))
         end
    end

    if DEBUG_MODE then
        gfx.setColor(gfx.kColorBlack)
        playdate.drawFPS(200, 120)
    end
end

-- Helpers
local function stopAllAudio()
    if Sound and Sound.stopAll then
        Sound.stopAll()
    end
end

function playdate.gameWillPause()
    saveGame(GameState.score)
    if Sound.pauseAll then Sound.pauseAll() end
end

function playdate.gameWillTerminate()
    saveGame(GameState.score)
    cleanupScene()
end

local function syncMusicToState()
    if Sound.isMuted() then
        Sound.stopAll()
        return
    end

    if GameState.state == "splash" or GameState.state == "credits" then
        -- force restart (helps simulator)
        Sound.recreateTitlePlayer()
        Sound.playTitleMusicFile()
    else
        Sound.stopTitleMusicFile()
        --if Sound.playGameplayMusicFile then
        --    Sound.playGameplayMusicFile()
        --end
    end
end

function playdate.gameWillResume()
    if Sound.isMuted() then return end

    -- Defer restart until the game loop is running again
    playdate.timer.performAfterDelay(1, function()
        if Sound.isMuted() then return end
        if GameState.state == "splash" or GameState.state == "credits" then
            Sound.forceRestartTitle()
        end
    end)
end

function playdate.deviceWillLock()
    playdate.gameWillPause()
end

function playdate.deviceWillSleep()
    saveGame(GameState.score)
    if Sound and Sound.pauseAll then Sound.pauseAll() end
    if Sound and Sound.stopAll then Sound.stopAll() end
end

function playdate.deviceDidWake()
    if Sound.resumeAll then Sound.resumeAll() end
    syncMusicToState()
end

function playdate.deviceDidUnlock()
    if Sound.resumeAll then Sound.resumeAll() end
    syncMusicToState()
end