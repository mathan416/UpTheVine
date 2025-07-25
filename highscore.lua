local GameData = {
    highScore = 12345,
    achievements = {
        vineMaster = false,
        firstBlood = false,
        unstoppable = false
    }
}

-- Save Game Data 
local function saveGame()
    playdate.datastore.write(GameData, "UpTheVine")
end

-- Load Game Data
local function loadSavedGame()
    GameData = playdate.datastore.read("UpTheVine")

    if GameData then
        print("High score:", GameData.highScore)
    else
        print("No save file yet")
    end
end