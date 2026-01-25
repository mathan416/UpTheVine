local GameData = {
    highScore = 0,
    achievements = {
        vineMaster = false,
        firstBlood = false,
        unstoppable = false
    }
}

-- Save Game Data 
function saveGame(score)
    if score > GameData.highScore then
        GameData.highScore = score
    end
    playdate.datastore.write(GameData, "UpTheVine2")
end

-- Load Game Data
function loadSavedGame()
    local data = playdate.datastore.read("UpTheVine2")
    if data then
        GameData = data
        print("High score loaded:", GameData.highScore)
    else
        print("No save file yet, starting fresh")
    end
    return GameData.highScore
end

-- Get current high score
function getHighScore()
    return GameData.highScore
end