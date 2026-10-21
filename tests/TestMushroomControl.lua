-- Run inside Lua 5.3. All show/MIDI/time calls below are simulated. Loading the
-- candidate in a separate environment never replaces the live Mushroom table.
return function(sourcePath, resultPath)
    local passed = 0
    local function eq(actual, expected, context)
        assert(actual == expected, (context or "value") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
    local function fixture(levels)
        local s = { now = 0, tasks = {}, commands = {}, midi = {}, current = nil, epoch = 0 }
        local env = setmetatable({}, { __index = _G })
        env._G = env
        env.Mushroom = { started = true, _audioLevels = levels or
            { water = 45, night = 0, day = 50, thunderstorm = 0 } }
        local M
        local cues = { "1", "1.1", "1.2", "1.3", "1.4", "2", "3", "4" }
        local names = { "day", "thunderstorm", "rainbow", "rainbowOff", "newday", "dusk", "night", "dawn" }
        local function resume(task)
            local ok, delay = coroutine.resume(task.co)
            assert(ok, delay)
            if coroutine.status(task.co) ~= "dead" then
                task.due = s.now + (delay or 0)
                s.tasks[#s.tasks + 1] = task
            end
        end
        function s.start(fn) resume({ co = coroutine.create(fn) }) end
        function s.advance(seconds)
            local untilTime = s.now + seconds
            while true do
                local selected
                for i, task in ipairs(s.tasks) do
                    if task.due <= untilTime and (not selected or task.due < s.tasks[selected].due) then selected = i end
                end
                if not selected then break end
                local task = table.remove(s.tasks, selected)
                s.now = task.due
                resume(task)
            end
            s.now = untilTime
        end
        local function enter(index)
            s.current = cues[index]
            s.epoch = s.epoch + 1
            local epoch = s.epoch
            s.start(function()
                coroutine.yield(40)
                if s.epoch == epoch then enter(index % #cues + 1) end
            end)
            s.start(function() M.OnCue(names[index]) end)
        end
        env.gma = {
            feedback = function() end,
            sleep = function(delay) return coroutine.yield(delay) end,
            gettime = function() return s.now end,
            timer = function(fn, interval, count)
                s.start(function()
                    for _ = 1, count do coroutine.yield(interval); fn() end
                end)
            end,
            show = {
                getobj = { handle = function(path)
                    if path == "Executor 1.106 Cue" then return s.current end
                    for _, cue in ipairs(cues) do if path == "Sequence 2 Cue " .. cue then return cue end end
                    if s.feedbackInstalled then
                        for i = 1, 5 do
                            if path == "Sequence " .. (1000 + i) .. " Cue 1"
                                or (not s.feedbackReassigned and path == "Executor 1." .. (200 + i) .. " Cue 1") then
                                return "feedback:" .. i
                            end
                        end
                    end
                end, number = function(handle) return handle end },
                property = { get = function() return "40" end }
            },
            cmd = function(command)
                s.commands[#s.commands + 1] = { time = s.now, text = command }
                local cc, value = command:match("^MidiControl (%d+) (%d+)$")
                if cc then s.midi[#s.midi + 1] = { cc = tonumber(cc), value = tonumber(value), time = s.now } end
                local cue = command:match("^Goto Cue ([%d%.]+) Executor 1%.106 Fade ")
                if cue then
                    for index, number in ipairs(cues) do if number == cue then enter(index); return end end
                    error("Unexpected cue " .. cue)
                end
            end
        }
        local chunk = assert(loadfile(sourcePath, "t", env))
        local entry = chunk()
        M = env.Mushroom
        s.M = M
        s.env = env
        s.entry = entry
        s.names = names
        s.cues = cues
        function s.checkAudio(period)
            local target = M.AudioTarget(period)
            for key, value in pairs(target) do eq(M._audioLevels[key], value, period .. " " .. key) end
        end
        function s.touch(period) s.start(function() M.SelectPeriod(period) end) end
        return s
    end
    local function test(name, fn)
        fn()
        passed = passed + 1
    end
    local ok, err = pcall(function()
        test("feedback for each sensor releases only its executor", function()
            for note = 48, 52 do
                local s = fixture()
                s.feedbackInstalled = true
                local fixtures = { [48] = 1102, [49] = 1101, [50] = 1104, [51] = 1105, [52] = 1103 }
                eq(s.M.CONFIG.touch.feedback.targets[note].fixture, fixtures[note], "physical sensor/light mapping")
                s.start(function() s.M.SelectNote(note) end)
                local executor = "1." .. (201 + note - 48)
                local found = false
                for _, command in ipairs(s.commands) do
                    if command.text == "Goto Cue 1 Executor " .. executor .. " Fade 0.05" then found = true end
                end
                eq(found, true, "sensor feedback executor")
                s.advance(0.39)
                for _, command in ipairs(s.commands) do
                    assert(command.text ~= "Off Executor " .. executor .. " Fade 0.35", "feedback released early")
                end
                s.advance(0.02)
                local releases = 0
                for _, command in ipairs(s.commands) do
                    if command.text == "Off Executor " .. executor .. " Fade 0.35" then releases = releases + 1 end
                end
                eq(releases, 1, "one feedback release")
            end
        end)
        test("feedback retrigger cannot be released by an older timer", function()
            local s = fixture()
            s.feedbackInstalled = true
            eq(s.M.TouchFeedback(48), true)
            s.advance(0.2)
            eq(s.M.TouchFeedback(48), true)
            s.advance(0.21)
            eq(s.commands[#s.commands].text, "Goto Cue 1 Executor 1.201 Fade 0.05")
            s.advance(0.2)
            eq(s.commands[#s.commands].text, "Off Executor 1.201 Fade 0.35")
        end)
        test("missing or reassigned feedback resources do not flash", function()
            local s = fixture()
            eq(s.M.TouchFeedback(48), false)
            s.feedbackInstalled = true
            s.feedbackReassigned = true
            eq(s.M.TouchFeedback(48), false)
            eq(#s.commands, 0)
        end)
        test("feedback does not flash on automatic cue continuation", function()
            local s = fixture()
            s.feedbackInstalled = true
            s.touch("day")
            s.advance(41)
            for _, command in ipairs(s.commands) do
                assert(not command.text:match("Executor 1%.20[1-5]"), "automatic cues must not flash sensors")
            end
        end)
        test("different sensor feedback timers remain independent", function()
            local s = fixture()
            s.feedbackInstalled = true
            s.M.TouchFeedback(48)
            s.advance(0.2)
            s.M.TouchFeedback(49)
            s.advance(0.21)
            eq(s.commands[#s.commands].text, "Off Executor 1.201 Fade 0.35")
            s.advance(0.2)
            eq(s.commands[#s.commands].text, "Off Executor 1.202 Fade 0.35")
        end)
        test("a definition reload preserves a running audio fade", function()
            local s = fixture()
            s.start(function() s.M.TransitionAudio(s.M.AudioTarget("thunderstorm"), 2) end)
            s.advance(1)
            assert(loadfile(sourcePath, "t", s.env))()
            s.advance(1.1)
            s.checkAudio("thunderstorm")
        end)
        test("definition-only hot load", function()
            local s = fixture()
            eq(#s.commands, 0)
            eq(s.M.started, true)
            s.start(s.entry)
            eq(#s.commands, 0, "already-started entry must not restart show/transport")
        end)
        for _, from in ipairs(fixture().names) do
            for index, to in ipairs(fixture().names) do
                test(from .. " to " .. to, function()
                    local s = fixture()
                    s.M._audioLevels = s.M.AudioTarget(from)
                    s.touch(to)
                    eq(s.current, s.cues[index], "daily position")
                    eq(s.M._lastWasTouch, true)
                    s.advance(2.01)
                    s.checkAudio(to)
                    eq(s.current, s.cues[index], "touch must not advance prematurely")
                    s.advance(37.98)
                    eq(s.current, s.cues[index])
                    s.advance(0.02)
                    eq(s.current, s.cues[index % #s.cues + 1], "normal timed continuation")
                    eq(s.M._lastWasTouch, false)
                end)
            end
        end
        test("superseded fades stop writing", function()
            local s = fixture()
            s.touch("thunderstorm")
            s.advance(0.7)
            local oldGeneration = s.M._audioGeneration
            local before = {}
            for key, value in pairs(s.M._audioLevels) do before[key] = value end
            s.touch("night")
            for key, value in pairs(before) do eq(s.M._audioLevels[key], value, "new fade starts at last sent value") end
            eq(s.M.SendCC("day", 127, oldGeneration), false)
            s.advance(2.1)
            s.checkAudio("night")
            s.advance(10)
            s.checkAudio("night")
        end)
        test("queued old cue cannot overwrite a newer selection", function()
            local s = fixture()
            s.touch("night")
            s.advance(2.1)
            local count = #s.commands
            s.M._pendingTouch = { period = "night", fade = 2 }
            eq(s.M.OnCue("thunderstorm"), false)
            eq(#s.commands, count)
            eq(s.M._pendingTouch.period, "night")
            s.checkAudio("night")
        end)
        test("rapid different sensors and debounce", function()
            local s = fixture()
            s.touch("day")
            local epoch = s.epoch
            s.advance(0.1)
            s.touch("day")
            eq(s.epoch, epoch, "bounce must not reset timer")
            s.touch("rainbow")
            eq(s.current, "1.2")
            s.advance(0.1)
            s.touch("thunderstorm")
            s.advance(2.1)
            s.checkAudio("thunderstorm")
        end)
        test("legacy in-flight fade cannot write", function()
            local s = fixture()
            eq(s.M.SendCC("day", 127), false)
            eq(#s.midi, 0)
        end)
        test("arbitrary current mixture", function()
            local s = fixture({ water = 45, day = 17, night = 39, thunderstorm = 12 })
            s.touch("rainbow")
            eq(s.M._audioLevels.night, 39)
            eq(s.M._audioLevels.day, 17)
            s.advance(2.1)
            s.checkAudio("rainbow")
        end)
        test("all eight automatic periods", function()
            local s = fixture()
            s.touch("day")
            s.advance(320.01)
            eq(s.current, "1", "wrap to first Day")
            s.checkAudio("day")
            for _, message in ipairs(s.midi) do
                assert(message.cc >= 49 and message.cc <= 52, "Unexpected transport/MIDI command")
                assert(message.value >= 0 and message.value <= 127)
                if message.cc == 49 then eq(message.value, 45, "Water audio preserved") end
            end
        end)
        test("invalid input has no side effects", function()
            local s = fixture()
            eq(pcall(s.M.SelectPeriod, "invalid"), false)
            eq(#s.commands, 0)
        end)
        test("five existing sensor notes", function()
            local s = fixture()
            local expected = { [48] = "day", [49] = "dusk", [50] = "night", [51] = "rainbow", [52] = "thunderstorm" }
            for note, period in pairs(expected) do eq(s.M.CONFIG.touch.notes[note], period) end
        end)
        for note, cue in pairs({ [48] = "1", [49] = "2", [50] = "3", [51] = "1.2", [52] = "1.1" }) do
            test("note dispatch " .. note, function()
                local s = fixture()
                s.start(function() s.M.SelectNote(note) end)
                eq(s.current, cue)
            end)
        end
        test("evening aliases Night", function()
            local s = fixture()
            s.touch("evening")
            eq(s.current, "3")
            s.advance(2.1)
            s.checkAudio("night")
        end)
        test("startup retains its separate transport pulse", function()
            local s = fixture()
            s.M.started = false
            s.start(s.entry)
            s.advance(12)
            local values = {}
            for _, message in ipairs(s.midi) do if message.cc == 53 then values[#values + 1] = message.value end end
            eq(#values, 2)
            eq(values[1], 127)
            eq(values[2], 0)
            s.checkAudio("day")
        end)
    end)
    local result = assert(io.open(resultPath, "w"))
    result:write(ok and "PASS" or "FAIL", "\nTests passed: ", tostring(passed), "\nLua: ", _VERSION, "\n")
    if not ok then result:write(tostring(err), "\n") end
    result:close()
    assert(ok, err)
    return passed
end
