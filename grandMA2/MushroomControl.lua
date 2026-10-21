_G.Mushroom = _G.Mushroom or {}
local M = _G.Mushroom
M.VERSION = "2026-10-21-touch-v3"

M.CONFIG = {

    audio = {
        water        = { cc = 49, level = 45 },
        night        = { cc = 50, level = 50 },
        day          = { cc = 51, level = 50 },
        thunderstorm = { cc = 52, level = 30 },
        transport    = { cc = 53, level = 127 }
    },

    startup = {
        waitForStudioOne = 10,
        startExecutor106 = true
    },

    timing = {
        day          = 40,
        thunderstorm = 40,
        rainbow      = 40,
        rainbowOff   = 40,
        newday       = 40,
        dusk         = 40,
        night        = 40,
        dawn         = 40
    },

    fade = {
        thunderstorm = 10,
        rainbow      = 10,
        reconcile    = 2
    },

    touch = {
        fade = 2,
        debounce = 0.5,
        executor = "1.106",
        feedback = {
            enabled = true,
            attack = 0.05,
            hold = 0.4,
            release = 0.35,
            targets = {
                [48] = { fixture = 1102, sequence = 1001, executor = "1.201" },
                [49] = { fixture = 1101, sequence = 1002, executor = "1.202" },
                [50] = { fixture = 1104, sequence = 1003, executor = "1.203" },
                [51] = { fixture = 1105, sequence = 1004, executor = "1.204" },
                [52] = { fixture = 1103, sequence = 1005, executor = "1.205" }
            }
        },
        notes = {
            [48] = "day", [49] = "dusk", [50] = "night",
            [51] = "rainbow", [52] = "thunderstorm"
        }
    },

    periods = {
        day          = { cue = "1",   audio = "day",   lighting = "1.111" },
        thunderstorm = { cue = "1.1", audio = "thunderstorm", lighting = "1.105" },
        rainbow      = { cue = "1.2", audio = "day",   lighting = "1.113" },
        rainbowOff   = { cue = "1.3", audio = "day",   lighting = "1.111" },
        newday       = { cue = "1.4", audio = "day",   lighting = "1.111" },
        dusk         = { cue = "2",   audio = "night" },
        night        = { cue = "3",   audio = "night" },
        dawn         = { cue = "4",   audio = "day" }
    }
}


------------------------------------------------------------
-- MIDI helpers
------------------------------------------------------------

M._audioLevels = M._audioLevels or { water = 0, night = 0, day = 0, thunderstorm = 0 }
-- Definition-only updates keep compatible in-flight fades alive. Starting a
-- new transition below is the operation that cancels previous generations.
M._audioGeneration = M._audioGeneration or 0
local audioNames = { "water", "night", "day", "thunderstorm" }

function M.SendCC(name, value, generation, force)

    -- Old, already-running crossfades have no generation argument. Refuse their
    -- writes after a hot update, as well as writes from superseded new fades.
    if generation ~= M._audioGeneration then return false end

    local a = M.CONFIG.audio[name]

    if not a then
        gma.feedback("Unknown audio control: " .. tostring(name))
        return
    end

    value = math.max(0, math.min(127, math.floor(value + 0.5)))
    if not force and M._audioLevels[name] == value then return true end
    gma.cmd(
        "MidiControl " ..
        tostring(a.cc) ..
        " " ..
        tostring(value)
    )

    M._audioLevels[name] = value
    return true

end


------------------------------------------------------------
-- Generic two-channel crossfade
------------------------------------------------------------

function M.TransitionAudio(target, duration)
    assert(type(duration) == "number" and duration >= 0, "Invalid audio fade")
    local from = {}
    for _, name in ipairs(audioNames) do
        assert(type(target[name]) == "number", "Missing target: " .. name)
        assert(type(M._audioLevels[name]) == "number", "Unknown current level: " .. name)
        from[name] = M._audioLevels[name]
    end
    M._audioGeneration = M._audioGeneration + 1
    local generation = M._audioGeneration
    -- Twenty samples per second for short fades, bounded work for long fades.
    local steps = duration == 0 and 0 or math.min(200, math.max(1, math.ceil(duration * 20)))
    for i = 0, steps do
        if generation ~= M._audioGeneration then return false end
        local fraction = steps == 0 and 1 or i / steps
        for _, name in ipairs(audioNames) do
            M.SendCC(name, from[name] + (target[name] - from[name]) * fraction,
                generation, i == steps)
        end
        if i < steps then gma.sleep(duration / steps) end
    end
    return true
end

function M.AudioTarget(period)
    local p = assert(M.CONFIG.periods[period], "Unknown period: " .. tostring(period))
    local target = { water = M.CONFIG.audio.water.level, night = 0, day = 0, thunderstorm = 0 }
    target[p.audio] = M.CONFIG.audio[p.audio].level
    return target
end

-- Kept for existing external callers; starting levels always come from the
-- values actually sent, and all environmental tracks participate in the fade.
function M.Crossfade(fromName, fromLevel, toName, toLevel, duration)
    local target = { water = M.CONFIG.audio.water.level, night = 0, day = 0, thunderstorm = 0 }
    assert(target[toName] ~= nil, "Unknown target audio track")
    target[toName] = toLevel
    return M.TransitionAudio(target, duration)
end


------------------------------------------------------------
-- Sequence timing helper
------------------------------------------------------------

function M.GetCueDuration(cue)

    local h =
        gma.show.getobj.handle(
            "Sequence 2 Cue " .. tostring(cue)
        )

    if not h then
        gma.feedback(
            "Could not find Sequence 2 Cue " ..
            tostring(cue)
        )
        return nil
    end

    return tonumber(
        gma.show.property.get(h, 3)
    )

end


------------------------------------------------------------
-- Audio transitions
------------------------------------------------------------

function M.Thunderstorm()

    M.Crossfade(
        "day",
        M.CONFIG.audio.day.level,
        "thunderstorm",
        M.CONFIG.audio.thunderstorm.level,
        M.CONFIG.fade.thunderstorm
    )

end


function M.Day()

    M.Crossfade(
        "thunderstorm",
        M.CONFIG.audio.thunderstorm.level,
        "day",
        M.CONFIG.audio.day.level,
        M.CONFIG.fade.rainbow
    )

end


function M.Dusk()

    local duration = M.GetCueDuration("2")

    if not duration then
        return
    end

    M.Crossfade(
        "day",
        M.CONFIG.audio.day.level,
        "night",
        M.CONFIG.audio.night.level,
        duration
    )

end


function M.Dawn()

    local duration = M.GetCueDuration("4")

    if not duration then
        return
    end

    M.Crossfade(
        "night",
        M.CONFIG.audio.night.level,
        "day",
        M.CONFIG.audio.day.level,
        duration
    )

end


------------------------------------------------------------
-- Studio One transport
------------------------------------------------------------

function M.StartTransport()

    local t = M.CONFIG.audio.transport

    gma.cmd(
        "MidiControl " ..
        tostring(t.cc) ..
        " " ..
        tostring(t.level)
    )

    gma.sleep(0.2)

    gma.cmd(
        "MidiControl " ..
        tostring(t.cc) ..
        " 0"
    )

end


------------------------------------------------------------
-- Known startup audio state
------------------------------------------------------------

function M.SetStartupAudio()
    M.TransitionAudio(M.AudioTarget("day"), 0)
end


------------------------------------------------------------
-- Sequence 2 cue map
------------------------------------------------------------

local cueMap = {
    { name = "day",          cue = "1"   },
    { name = "thunderstorm", cue = "1.1" },
    { name = "rainbow",      cue = "1.2" },
    { name = "rainbowOff",   cue = "1.3" },
    { name = "newday",       cue = "1.4" },
    { name = "dusk",         cue = "2"   },
    { name = "night",        cue = "3"   },
    { name = "dawn",         cue = "4"   }
}


------------------------------------------------------------
-- Read Sequence 2 timings
------------------------------------------------------------

function M.ReadTimings()

    gma.feedback(
        "---- Sequence 2 current timings ----"
    )

    for _, item in ipairs(cueMap) do

        local h =
            gma.show.getobj.handle(
                "Sequence 2 Cue " ..
                item.cue
            )

        if h then

            local t =
                gma.show.property.get(
                    h,
                    3
                )

            gma.feedback(
                item.name ..
                " Cue " ..
                item.cue ..
                " TrigTime=" ..
                tostring(t)
            )

        else

            gma.feedback(
                "Could not find Sequence 2 Cue " ..
                item.cue
            )

        end

    end

end


------------------------------------------------------------
-- Apply configured Sequence timing
------------------------------------------------------------

function M.ApplyTimings()

    for _, item in ipairs(cueMap) do

        local value =
            M.CONFIG.timing[item.name]

        if value ~= nil then

            gma.cmd(
                "Assign Sequence 2 Cue " ..
                item.cue ..
                " /TrigTime=" ..
                tostring(value)
            )

        end

    end

    gma.feedback(
        "Mushroom timing configuration applied"
    )

end


------------------------------------------------------------
-- Complete startup
------------------------------------------------------------

function M.Startup()

    if M.started then
        gma.feedback(
            "Mushroom startup already executed"
        )
        return
    end

    M.started = true

    gma.feedback(
        "Mushroom startup beginning"
    )

    -- Make Sequence 2 match CONFIG
    M.ApplyTimings()

    -- Give Studio One and LoopBe time to initialize
    gma.sleep(
        M.CONFIG.startup.waitForStudioOne
    )

    -- Put audio into a known Day state
    M.SetStartupAudio()

    -- Start Studio One playback
    M.StartTransport()

    -- Allow transport to settle
    gma.sleep(1)

    -- Start Daily Cycle at Cue 1
    if M.CONFIG.startup.startExecutor106 then

        gma.cmd(
            "Goto Cue 1 Executor 106"
        )

    end

    gma.feedback(
        "Mushroom startup complete"
    )

end


------------------------------------------------------------
-- Allow manual re-test of startup
------------------------------------------------------------

function M.ResetStartup()

    M.started = false

    gma.feedback(
        "Mushroom startup reset"
    )

end


------------------------------------------------------------
-- Plugin entry point
------------------------------------------------------------

-- Sequence 2 calls this for every period, including Day and Night. A direct
-- jump therefore applies a complete audio state instead of relying on earlier
-- cues having silenced the other tracks. Stored fixture/effect data stays in
-- Sequence 2; this only replaces its transition commands.
function M.OnCue(period)
    local p = assert(M.CONFIG.periods[period], "Unknown period: " .. tostring(period))
    local current = gma.show.getobj.handle("Executor " .. M.CONFIG.touch.executor .. " Cue")
    if not current or tonumber(gma.show.getobj.number(current)) ~= tonumber(p.cue) then
        -- grandMA2 can queue a macro behind another Lua command. An old cue's
        -- callback must not take lighting/audio ownership after a newer touch.
        return false
    end
    local touch = M._pendingTouch
    local touched = touch and touch.period == period
    if touched then M._pendingTouch = nil end
    local suffix = touched and (" Fade " .. tostring(touch.fade)) or ""

    -- Release old overlays when jumping across the cycle. Keep the target
    -- overlay running when it is already active, avoiding an Off/Go blackout.
    for _, executor in ipairs({ "1.101", "1.102", "1.103", "1.104",
        "1.105", "1.109", "1.111", "1.113" }) do
        if executor ~= p.lighting then gma.cmd("Off Executor " .. executor .. suffix) end
    end
    if p.lighting then gma.cmd("Go Executor " .. p.lighting .. suffix) end

    local duration = touched and touch.fade or M.CONFIG.fade.reconcile
    if not touched then
        if period == "thunderstorm" then duration = M.CONFIG.fade.thunderstorm
        elseif period == "rainbow" then duration = M.CONFIG.fade.rainbow
        elseif period == "dusk" then duration = assert(M.GetCueDuration("2"))
        elseif period == "dawn" then duration = assert(M.GetCueDuration("4")) end
    end
    M._lastPeriod = period
    M._lastWasTouch = not not touched
    -- Start feedback after the scene overlay, so its Super-priority white
    -- pulse can be seen even when Thunderstorm also owns this mushroom.
    if touched and touch.note then M.TouchFeedback(touch.note) end
    return M.TransitionAudio(M.AudioTarget(period), duration)
end

function M.SelectPeriod(period, note)
    if period == "evening" then period = "night" end
    local p = assert(M.CONFIG.periods[period], "Unknown period: " .. tostring(period))
    assert(gma.show.getobj.handle("Sequence 2 Cue " .. p.cue), "Missing daily cue")
    local now = gma.gettime()
    if M._lastTouch and M._lastTouch.period == period
        and now - M._lastTouch.time < M.CONFIG.touch.debounce then return false end
    M._lastTouch = { period = period, time = now }
    M._pendingTouch = { period = period, fade = M.CONFIG.touch.fade, note = note }
    -- Goto resets the timed progression at this cue, including the first Day.
    -- No separate loop/timer runs in Lua and no transport command is needed.
    gma.cmd("Goto Cue " .. p.cue .. " Executor " .. M.CONFIG.touch.executor
        .. " Fade " .. tostring(M.CONFIG.touch.fade))
    return true
end

M._feedbackGeneration = M._feedbackGeneration or {}

function M.TouchFeedback(note)
    local feedback = M.CONFIG.touch.feedback
    local target = feedback and feedback.targets[note]
    if not feedback or not feedback.enabled or not target then return false end
    local cue = gma.show.getobj.handle("Sequence " .. target.sequence .. " Cue 1")
    local assigned = gma.show.getobj.handle("Executor " .. target.executor .. " Cue 1")
    -- Never flash an executor that has been repurposed or was not installed.
    if not cue or cue ~= assigned then return false end
    local generation = (M._feedbackGeneration[note] or 0) + 1
    M._feedbackGeneration[note] = generation
    gma.cmd("Goto Cue 1 Executor " .. target.executor .. " Fade " .. feedback.attack)
    gma.timer(function()
        if M._feedbackGeneration[note] ~= generation then return end
        if gma.show.getobj.handle("Executor " .. target.executor .. " Cue 1") ~= cue then return end
        gma.cmd("Off Executor " .. target.executor .. " Fade " .. feedback.release)
    end, feedback.hold, 1)
    return true
end

function M.SelectNote(note)
    local period = assert(M.CONFIG.touch.notes[note], "Unmapped touch note: " .. tostring(note))
    local selected = M.SelectPeriod(period, note)
    -- Show an incoming trigger even if same-period debounce suppresses its jump.
    if not selected then M.TouchFeedback(note) end
    return selected
end

return function()

    gma.feedback(
        "Mushroom Control loaded"
    )

    M.Startup()

end
