import "CoreLibs/sound"


-- soundmanager.lua
local snd = playdate.sound

function playDiamondPickupSound()
    local baseNote = 100  -- Base MIDI note
    local intervals = {0, 3, 7, 12} -- Minor 3rd chord with an octave
    local delayBetween = 40         -- ms between each note
    local volume = 0.5

    for i, interval in ipairs(intervals) do
        local synth = snd.synth.new(snd.kWaveSine)
        synth:setAttack(0.01)
        synth:setDecay(0.1)
        synth:setSustain(0.1)
        synth:setRelease(0.2)

        local channel = snd.channel.new()
        channel:addSource(synth)

        -- Alternate stereo pan for flutter effect
        local pan = ((i % 2) == 0) and -0.7 or 0.7
        channel:setPan(pan)

        local delay = (i - 1) * delayBetween
        playdate.timer.performAfterDelay(delay, function()
            synth:playNote(baseNote + interval, volume)
        end)
    end
end

function playDiamondSound()
    local synth = snd.synth.new(snd.kWaveSine)
    synth:setAttack(0.01)
    synth:setDecay(0.1)
    synth:setSustain(0.2)
    synth:setRelease(0.3)
    synth:playNote(104, 0.4) -- high-pitched "tinkling"
end

function playFlyingEnemyHitSound()
    local synth = snd.synth.new(snd.kWaveSquare)
    synth:setAttack(0.01)
    synth:setDecay(0.2)
    synth:setSustain(0.1)
    synth:setRelease(0.2)
    synth:playNote(64, 0.4) -- squawky mid-tone
end

function playVineEnemyHitSound()
    local synth = snd.synth.new(snd.kWaveSawtooth)
    synth:setAttack(0.05)
    synth:setDecay(0.2)
    synth:setSustain(0.2)
    synth:setRelease(0.3)
    synth:playNote(48, 0.5) -- low jungle-like rumble
end

For collectable:update()    -- Replace this with your actual collision logic
    if self:collidesWith(player) then
        GameState.score += 100
        self:remove()
        playDiamondPickupSound()  -- ← Add sound here
    end

    -- Inside player collision with FlyingEnemy
if player:collidesWith(self) then
    playFlyingEnemyHitSound()
    -- handle collision
end

if player:collidesWith(self) then
    playVineEnemyHitSound()
    -- handle collision
end