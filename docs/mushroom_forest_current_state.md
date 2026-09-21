# Mushroom Forest – Current System Checkpoint

**Checkpoint:** September 21, 2026

This document describes the current working Mushroom Forest lighting/audio system, its configuration, and the planned next steps.

## System Architecture

The installation currently uses:

- **grandMA2 onPC v3.9.60.28** as the master show/state controller.
- **Studio One 5** for continuous environmental audio.
- **LoopBe Internal MIDI** to carry MIDI from grandMA2 to Studio One.
- Mushroom controllers send MIDI inputs to grandMA2.
- grandMA2 controls both the lighting state and the corresponding Studio One audio state.

The intended architecture is:

Mushrooms / automatic sequence -> grandMA2 -> lighting + MIDI audio control -> Studio One

grandMA2 is the master state machine.

## grandMA2 Daily Cycle

Executor **106 – Daily Cycle** runs **Sequence 2**.

Current cue structure:

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

Cue 4 loops back to Cue 1.

Each cue has its own **Trig Time**, so different parts of the show can have different durations.

For example, Thunderstorm could eventually be 30 seconds while Rainbow is 60 seconds, Night is several minutes, etc.

## Important Executors

- 102 – Dark Mode
- 103 – Night
- 104 – Rainbow wrapper
- 105 – Thunderstorm
- 106 – Daily Cycle
- 109 – Dark Mode
- 111 – Day
- 113 – Rainbow
- 115 – White

Important discovery:

Executor 106 originally had **Off On Overwritten** enabled. This caused the Daily Cycle to stop when another executor such as Rainbow took control.

**Off On Overwritten is now OFF on Executor 106.**

This allows Daily Cycle to continue underneath temporary effects.

## Daily Cycle Lighting Commands

Current Sequence 2 commands include:

Cue 1 Day:

    Go Executor 111

Cue 1.1 Thunderstorm:

    Off Executor 111 ; Go Executor 105 ; Macro 22

Cue 1.2 Rainbow:

    Off Executor 105 ; Go Executor 113 ; Macro 21

Cue 1.3 Rainbow Off:

    Off Executor 113 ; Go Executor 111

Cue 2 Dusk:

    Off Executor 113 ; Off Executor 105 ; Off Executor 111 ; Macro 23

Cue 3 Night:

    Off Executor 113 ; Off Executor 109

Cue 4 Dawn:

    Off Executor 113 ; Off Executor 109 ; Macro 24

## Studio One Audio

The Studio One song contains continuous environmental audio tracks.

Important tracks:

- Water
- day-forest
- night-forest
- thunderstorm

There is also an unused/duplicate thunderstorm track. The real thunderstorm waveform used by the system is the mapped thunderstorm track.

Rainbow currently has no separate soundtrack and uses the Day audio.

Dawn and Dusk are audio transitions rather than separate recordings.

## MIDI Audio Mapping

grandMA2 sends MIDI Control Change commands to Studio One through LoopBe Internal MIDI.

Current mapping:

| Audio | MIDI CC | Nominal Level |
|---|---:|---:|
| Water | 49 | 41 |
| Night | 50 | 85 |
| Day | 51 | 85 |
| Thunderstorm | 52 | 41 |

A value of **0 means silent**.

These levels are provisional and should be tuned while physically listening in the Mushroom Forest.

Water is intended to remain a constant background layer and is not affected by normal Day/Night/Thunderstorm transitions.

## Studio One Control Surface

Studio One has a **New Control Surface** receiving from:

    LoopBe Internal MIDI

Learned controls exist for:

- CC49
- CC50
- CC51
- CC52

These are linked through Studio One Control Link to the corresponding track volume faders.

The Studio One settings folders `Surface Data[1]` and `User Devices` have been copied into the Git repository so these mappings can be reconstructed.

## Audio Macros

### Macro 21 – Audio Day

Used when leaving Thunderstorm and entering Rainbow/Day audio.

Thunderstorm fades from 41 -> 0.

Day fades from 0 -> 85.

Approximately 10-second transition.

### Macro 22 – Audio Thunderstorm

Used when entering Thunderstorm.

Day fades from 85 -> 0.

Thunderstorm fades from 0 -> 41.

Approximately 10-second transition.

### Macro 23 – Audio Dusk

Crossfades:

Day -> Night

The transition duration is read automatically from **Sequence 2 Cue 2 Trig Time**.

### Macro 24 – Audio Dawn

Crossfades:

Night -> Day

The transition duration is read automatically from **Sequence 2 Cue 4 Trig Time**.

## Lua Timing Discovery

grandMA2 Lua support was tested successfully.

The Daily Cycle executor is Executor 106, but its underlying sequence is:

    Sequence 2

For cue objects, property index **3** is:

    Trig Time

For example:

    gma.show.property.get(h,3)

can read the cue duration.

This allows audio fades to automatically follow the timing programmed into the Daily Cycle.

## Mushroom Config Plugin

Plugin **2** is named:

    Mushroom Config

The plugin currently establishes a central configuration structure:

    CONFIG = {
        audio = {
            water        = { cc = 49, level = 41 },
            night        = { cc = 50, level = 85 },
            day          = { cc = 51, level = 85 },
            thunderstorm = { cc = 52, level = 41 }
        },

        timing = {
            day          = 40,
            thunderstorm = 40,
            rainbow      = 40,
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

The plugin has been successfully executed and its configuration values verified.

Currently these configuration values do **not yet automatically update Sequence 2 or the audio macros**.

That is the next development step.

## Planned Central Configuration

The goal is for Mushroom Config to become the single place where show parameters are changed.

For example:

    audio.day.level
    audio.night.level
    audio.thunderstorm.level
    audio.water.level

and:

    timing.day
    timing.thunderstorm
    timing.rainbow
    timing.dusk
    timing.night
    timing.dawn

The plugin will eventually apply these values automatically to Sequence 2.

This will allow, for example:

    Thunderstorm = 30 sec
    Rainbow = 60 sec
    Dusk = 180 sec
    Night = 600 sec
    Dawn = 180 sec

without manually editing every cue.

## State Duration vs Crossfade Duration

These are deliberately separate concepts.

Example:

    Thunderstorm duration = 40 sec
    Thunderstorm audio fade = 10 sec

Dawn and Dusk are different: their Day/Night audio crossfades are intended to span essentially the entire Dawn/Dusk period.

## Planned Smarter Audio Engine

The current macros assume known starting levels.

The planned Lua audio engine will instead:

1. Maintain the current audio levels.
2. Accept a target state.
3. Smoothly interpolate from the actual current levels to the target levels.
4. Allow a new transition to interrupt a transition already in progress.
5. Continue smoothly from whatever intermediate levels currently exist.

This is particularly important for mushroom-triggered manual effects.

For example, if Thunderstorm is triggered halfway through Dawn, the system should transition from the current Day/Night mixture rather than assuming either Day or Night is at full level.

The same audio-state engine should eventually be used by both:

- Automatic Daily Cycle cues
- Mushroom/manual executor triggers

## MIDI Command Log Noise

The current audio fade macros repeatedly execute commands such as:

    MidiControl 51 ...
    MidiControl 52 ...

grandMA2 displays these commands in Command Line Feedback, producing substantial log noise during fades.

A future improvement is to move audio fading into the Lua plugin and investigate a quieter MIDI output mechanism rather than repeatedly calling `gma.cmd("MidiControl ...")`.

Do not disable useful global command feedback merely to hide this noise until a better solution is implemented.

## Current Working State

At this checkpoint:

- Daily Cycle lighting works.
- Lighting transitions work.
- Daily Cycle continues underneath temporary effects.
- Day audio works.
- Night audio works.
- Water audio works.
- Thunderstorm audio works.
- Day -> Thunderstorm audio crossfade works.
- Thunderstorm -> Day audio crossfade works.
- Day -> Night Dusk crossfade works.
- Night -> Day Dawn crossfade works.
- Dawn/Dusk audio duration follows the corresponding Sequence 2 cue timing.
- Plugin 2 Mushroom Config exists and executes successfully.

## Backup Files

The Git repository contains a current grandMA2 recovery show:

    grandMA2/mushroom_forest_audio_working_2026-09-21.show.gz

The Studio One song has been saved as a self-contained copy containing the song and its media.

Studio One control-surface settings are also being preserved.

Large WAV files are managed with Git LFS.

## Next Steps

When work resumes:

1. Preserve the current working MA show as the known-good checkpoint.
2. Extend Mushroom Config so its timing values automatically update Sequence 2.
3. Replace hard-coded audio levels in Macros 21-24 with centralized configuration values.
4. Develop the state-aware/interruption-safe audio transition engine.
5. Use the same audio-state mechanism for mushroom-triggered effects.
6. Reduce MIDI command-line log noise.
7. Tune actual audio levels while physically listening in the installation.
8. Export the Lua plugin separately for readable Git version history.

Do not remove or rewrite the currently working Macros 21-24 until their replacement has been tested successfully.
