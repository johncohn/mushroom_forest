# Mushroom Forest – Current System Documentation

**Current checkpoint:** September 23, 2026

This document describes the current working Mushroom Forest lighting/audio system, how the pieces fit together, what is controlled from configuration, what to edit when changing the show, and how to save/version the working system.

## 1. System Overview

The system currently uses:

- **grandMA2 onPC v3.9.60** as the master show/state controller.
- **Studio One 5** for continuous environmental audio playback.
- **LoopBe Internal MIDI** for MIDI from grandMA2 to Studio One.
- **Git/GitHub** repository: `https://github.com/johncohn/mushroom_forest`

grandMA2 is the master state machine. Studio One continuously plays the environmental tracks, while grandMA2 controls their levels and transport.

## 2. Current Working Files

### grandMA2 live working show

```text
C:\ProgramData\MA Lighting Technologies\grandma\gma2_V_3.9.60\shows\mushroom_forest_current.show.gz
```

grandMA2 actively saves this file.

### Git-managed grandMA2 checkpoint

```text
C:\Users\Mushroom Forrest\Desktop\mushroom_forest\grandMA2\mushroom_forest_current.show.gz
```

The Git copy is a checkpoint. grandMA2 does not write directly into the Git repository.

### Studio One live working song

```text
C:\Users\Mushroom Forrest\Desktop\mushroom_forest\StudioOne\Mushroom Forest Sound_Current.song
```

Studio One is working directly from the Git-managed directory.

## 3. Studio One Tracks

Active environmental tracks:

- Water
- day-forest
- night-forest
- thunderstorm

A second hidden `night-forest` track was discovered and was causing unexpected extra Night volume. It should remain **muted**.

## 4. MIDI CC Assignments

| MIDI CC | Function | Configured Level |
|---:|---|---:|
| 49 | Water | 45 |
| 50 | Night forest | 50 |
| 51 | Day forest | 50 |
| 52 | Thunderstorm | 30 |
| 53 | Studio One Transport Start | 127 pulse |

`0` means silent for CC49-52.

CC53 is configured in Studio One as **Button (press/release)** assigned to:

```text
Transport -> Start
```

## 5. Daily Cycle – Executor 106

Executor 106 uses Sequence 2.

| Cue | State |
|---|---|
| 1 | Day |
| 1.1 | Thunderstorm |
| 1.2 | Rainbow |
| 1.3 | Rainbow Off |
| 1.4 | New Day |
| 2 | Dusk |
| 3 | Night |
| 4 | Dawn |

All current cue trigger times are temporarily **40 seconds** for development/testing.

## 6. Architecture

```text
Sequence 2 = lighting/show orchestration
Macros 21-24 = tiny audio transition launchers
Plugin 2 = audio logic, configuration, startup, and timing
```

## 7. Plugin 2 – Mushroom Control

Plugin 2 is the single configuration/control location.

Current important configuration:

```lua
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
        rainbow      = 10
    }
}
```

### What to edit

Change sound levels only in `M.CONFIG.audio`.

Change state durations only in `M.CONFIG.timing`.

Change Thunderstorm/return-to-Day audio crossfade durations in `M.CONFIG.fade`.

Change startup delay with:

```lua
waitForStudioOne = 10
```

## 8. Audio Transition Macros

Macro 21:

```text
Lua "Mushroom.Day()"
```

Macro 22:

```text
Lua "Mushroom.Thunderstorm()"
```

Macro 23:

```text
Lua "Mushroom.Dusk()"
```

Macro 24:

```text
Lua "Mushroom.Dawn()"
```

The macros contain no hard-coded sound levels.

## 9. Startup Behavior

Plugin 2 startup currently:

1. Applies configured Sequence 2 timings.
2. Waits for Studio One / LoopBe.
3. Sets:
   - Water = 45
   - Night = 0
   - Day = 50
   - Thunderstorm = 0
4. Pulses CC53 to start Studio One transport.
5. Starts Executor 106 at Cue 1 / Day.

Manual reset:

```text
Lua "Mushroom.ResetStartup()"
```

Manual startup:

```text
Lua "Mushroom.Startup()"
```

Plugin 2 has **Execute On Load = ON** for unattended startup.

## 10. Useful MA Commands

Stop Daily Cycle:

```text
Off Executor 106
```

Start Daily Cycle:

```text
Go Executor 106
```

Go directly to Day:

```text
Goto Cue 1 Executor 106
```

Load Mushroom Control:

```text
Plugin 2
```

Read current timings:

```text
Lua "Mushroom.ReadTimings()"
```

## 11. Git Workflow

Repository:

```text
C:\Users\Mushroom Forrest\Desktop\mushroom_forest
```

Before each checkpoint:

1. Save Studio One with `Ctrl+S`.
2. Save the grandMA2 show.
3. Copy the live MA2 show into Git:

```powershell
Copy-Item "C:\ProgramData\MA Lighting Technologies\grandma\gma2_V_3.9.60\shows\mushroom_forest_current.show.gz" "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\grandMA2\mushroom_forest_current.show.gz" -Force
```

4. Stage current files:

```powershell
git add "StudioOne/Mushroom Forest Sound_Current.song"
git add "grandMA2/mushroom_forest_current.show.gz"
git add "docs/mushroom_forest_current_state.md"
```

5. Commit and push:

```powershell
git commit -m "Describe checkpoint here"
git push
```

Studio One `Cache` and `History` are ignored.

## 12. Current Room-Tuned Audio Values

```text
Water        45
Day          50
Night        50
Thunderstorm 30
```

## 13. Known Studio One Details

- Keep the duplicate hidden `night-forest` track muted.
- The experimental master bus was not needed.
- Existing AC sends are part of the working routing; do not remove them casually.
- Transport must be running for sound; CC53 now starts it automatically.

## 14. Next Development Steps

1. Perform a true unattended Windows reboot test.
2. Confirm Studio One always opens `Mushroom Forest Sound_Current.song`.
3. Eliminate any MIDI-device startup prompt.
4. Confirm Plugin 2 Execute On Load runs reliably after cold boot.
5. Tune real show durations in `M.CONFIG.timing`.
6. Move additional Sequence fade/delay settings into config if desired.
7. Make audio transitions interruption-safe from actual current levels.
8. Reduce MA2 command-log spam from repeated `MidiControl` calls.
9. Export Mushroom Control as standalone Lua/XML for readable Git history.
10. Automate MA2-to-Git checkpoint copying.

## 15. Design Principle

```text
Edit configuration in one place.
```

That place is **Plugin 2 – Mushroom Control**.

Avoid reintroducing hard-coded levels or times into Macros 21-24.
