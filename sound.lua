local snd = playdate.sound

-- Public sound namespace
Sound = Sound or {}
Sound.muted = Sound.muted or false

-- ===== Splash / Title Music (MP3) =====
Sound._titlePlayer = Sound._titlePlayer or snd.fileplayer.new()
Sound._titleLoaded = Sound._titleLoaded or false
Sound._titlePath   = Sound._titlePath   or "sounds/Up_The_Vine"
Sound._titleRequested = Sound._titleRequested or false

if Sound._initialized then
    return
end
Sound._initialized = true

function Sound.setMuted(state)
    Sound.muted = state and true or false
    if Sound.muted then
        Sound.stopAll()
    end
end

function Sound.isMuted()
    return Sound.muted
end

-- Reusable sources
local diamondSynths = {}
local diamondChans = {}

local flyingHitSynth = snd.synth.new(snd.kWaveSquare)
flyingHitSynth:setAttack(0.01)
flyingHitSynth:setDecay(0.2)
flyingHitSynth:setSustain(0.0)
flyingHitSynth:setRelease(0.2)

local vineHitSynth = snd.synth.new(snd.kWaveSawtooth)
vineHitSynth:setAttack(0.05)
vineHitSynth:setDecay(0.2)
vineHitSynth:setSustain(0.0)
vineHitSynth:setRelease(0.3)

local gameOverSynth = snd.synth.new(snd.kWaveTriangle)
gameOverSynth:setAttack(0.005)
gameOverSynth:setDecay(0.12)
gameOverSynth:setSustain(0.0)
gameOverSynth:setRelease(0.25)

Sound._gameOverSeqId = Sound._gameOverSeqId or 0

local shuffleSynth = snd.synth.new(snd.kWaveNoise)
shuffleSynth:setAttack(0.005)
shuffleSynth:setDecay(0.05)
shuffleSynth:setSustain(0.0)
shuffleSynth:setRelease(0.06)

local shuffleMoving = false         -- ✅ “are we moving right now?”
local shuffleLastMs = 0
local shuffleIntervalMs = 120       -- tweak: 60–90 busier, 120–160 subtler

-- ✅ hard reset: safe to call on mute, scene changes, stopAll(), etc.
function Sound.stopShuffle()
    shuffleMoving = false
    shuffleLastMs = 0
    -- no need to synth:stop() because notes are short; avoids odd edge cases
end

-- Call every frame with true/false (and optional intensity 0..1)
function Sound.setShuffleMoving(isMoving, intensity)
    if Sound.muted then
        Sound.stopShuffle()
        return
    end

    -- Transition detection: stopped -> moving OR moving -> stopped
    if isMoving and not shuffleMoving then
        shuffleMoving = true
        -- ✅ restart-safe: fire immediately on start
        shuffleLastMs = playdate.getCurrentTimeMilliseconds() - shuffleIntervalMs
    elseif (not isMoving) and shuffleMoving then
        Sound.stopShuffle()
        return
    end

    if not shuffleMoving then return end

    local now = playdate.getCurrentTimeMilliseconds()
    if now - shuffleLastMs < shuffleIntervalMs then return end
    shuffleLastMs = now

    local amt = intensity or 1.0
    if amt < 0 then amt = 0 end
    if amt > 1 then amt = 1 end

    -- Slight randomization keeps it from “machine-gunning”
    local note = 38 + math.random(-3, 3)
    local vol  = 0.06 + (0.16 * amt)
    local dur  = 0.05 + (0.05 * amt)

    shuffleSynth:playNote(note, vol, dur)
end

-- ===== Splash / Title Music (MP3) =====
--local titlePlayer = snd.fileplayer.new()
--local titleLoaded = false
--local titlePath = "sounds/Up_The_Vine"

function Sound.playTitleMusicFile()
    if Sound.muted then return end
    local p = Sound._titlePlayer

    if not Sound._titleLoaded then
        Sound._titleLoaded = p:load(Sound._titlePath)
        if not Sound._titleLoaded then return end
        p:setVolume(0.6)
    end

    -- ✅ if we think we started it but it’s not playing anymore, allow restart
    if Sound._titleRequested and (not p:isPlaying()) then
        Sound._titleRequested = false
    end

    if Sound._titleRequested then return end
    Sound._titleRequested = true

    if p.setOffset then p:setOffset(0) end
    p:play(0)
end

function Sound.stopTitleMusicFile()
    local p = Sound._titlePlayer
    if p then
        if p:isPlaying() then p:stop() end
        if p.setOffset then p:setOffset(0) end
    end

    Sound._titleRequested = false
end

local function getDiamondVoice(i)
    if not diamondSynths[i] then
        local synth = snd.synth.new(snd.kWaveTriangle)
        synth:setAttack(0.001)
        synth:setDecay(0.06)
        synth:setSustain(0.0)
        synth:setRelease(0.08)

        local ch = snd.channel.new()
        ch:addSource(synth)

        diamondSynths[i] = synth
        diamondChans[i] = ch
    end
    return diamondSynths[i], diamondChans[i]
end

-- =========================
-- Namespaced SFX API
-- =========================

function Sound.playDiamondPickupSound()
    if Sound.muted then return end

    -- playNote() takes Hertz, so semitone intervals must be converted to a
    -- frequency ratio (2^(n/12)); adding them directly only shifts a few Hz.
    local baseHz = 1100
    local intervals = {0, 4, 7, 12}  -- semitones: root, major 3rd, 5th, octave
    local delayBetween = 30
    local volume = 0.4
    local noteDur = 0.08

    for i, interval in ipairs(intervals) do
        local synth, channel = getDiamondVoice(i)
        channel:setPan(((i % 2) == 0) and -0.7 or 0.7)

        local delay = (i - 1) * delayBetween
        playdate.timer.performAfterDelay(delay, function()
            if Sound.muted then return end
            local jitter = math.random(-1, 1) * 0.1 -- ±10 cents of sparkle
            local hz = baseHz * 2 ^ ((interval + jitter) / 12)
            synth:playNote(hz, volume, noteDur)
            synth:playNote(hz * 2, volume * 0.4, noteDur * 0.7) -- octave above
        end)
    end
end

local lastFlyingHitMs = -9999
function Sound.playFlyingEnemyHitSound()
    if Sound.muted then return end
    local now = playdate.getCurrentTimeMilliseconds()
    if now - lastFlyingHitMs < 80 then return end
    lastFlyingHitMs = now
    flyingHitSynth:playMIDINote(64, 0.5, 0.12) -- MIDI E4 (playNote would be 64 Hz)
end

local lastVineHitMs = -9999
function Sound.playVineEnemyHitSound()
    if Sound.muted then return end
    local now = playdate.getCurrentTimeMilliseconds()
    if now - lastVineHitMs < 80 then return end
    lastVineHitMs = now
    vineHitSynth:playMIDINote(48, 0.5, 0.18) -- MIDI C3 (playNote would be 48 Hz)
end

function Sound.playGameOverSound()
    if Sound.muted then return end

    Sound._gameOverSeqId += 1
    local seqId = Sound._gameOverSeqId

    local notes = { 900, 820, 740, 660 }
    local vol = 0.5
    local dur = 0.18

    for i, n in ipairs(notes) do
        playdate.timer.performAfterDelay((i - 1) * 110, function()
            if Sound.muted then return end
            if seqId ~= Sound._gameOverSeqId then return end -- cancel older sequences
            gameOverSynth:playNote(n, vol, dur)
        end)
    end
end

function Sound.stopAll()
    Sound.stopTitleMusicFile()
    Sound.stopShuffle() -- ✅ restart-safe reset

    if flyingHitSynth and flyingHitSynth.stop then flyingHitSynth:stop() end
    if vineHitSynth and vineHitSynth.stop then vineHitSynth:stop() end

    if diamondSynths then
        for _, syn in pairs(diamondSynths) do
            if syn and syn.stop then syn:stop() end
        end
    end
end

function Sound.pauseAll()
    Sound.stopShuffle()

    local p = Sound._titlePlayer
    if p then
        -- ✅ simulator-safe: stop instead of pause
        if p:isPlaying() then p:stop() end
        if p.setOffset then p:setOffset(0) end
    end

    -- ✅ allow restart on resume
    Sound._titleRequested = false
end

function Sound.resumeAll()
    -- Don’t blindly resume; let the game decide via syncMusicToState()
    -- (This exists so calls won’t error.)
end

function Sound.recreateTitlePlayer()
    -- Stop old one (best effort)
    if Sound._titlePlayer then
        if Sound._titlePlayer.isPlaying and Sound._titlePlayer:isPlaying() then
            Sound._titlePlayer:stop()
        end
    end

    Sound._titlePlayer = snd.fileplayer.new()
    Sound._titleLoaded = false
    Sound._titleRequested = false
end

function Sound.forceRestartTitle()
    -- Always restart from the beginning
    Sound.recreateTitlePlayer()
    Sound.playTitleMusicFile()
end