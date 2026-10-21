# Mushroom Forest – Current System Documentation

**Current checkpoint:** September 23, 2026

**Latest operational update:** October 21, 2026 (sections 20–22). The user
confirmed corrected mushroom flashes and sequencing. Studio One and grandMA2
were explicitly saved for the checkpoint in section 23. Thunderstorm
sound-reactive lightning remains unresolved, although the user confirmed the
storm scene otherwise works.

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
7. Audio transitions now start from last-sent levels and cancel superseded fades
   (sections 20–22); confirm physical audio through further use.
8. Reduce MA2 command-log spam from repeated `MidiControl` calls.
9. Mushroom Control now has readable Lua/XML source (sections 20–22).
10. Automate MA2-to-Git checkpoint copying.

## 15. Design Principle

```text
Edit configuration in one place.
```

That place is **Plugin 2 – Mushroom Control**.

Avoid reintroducing hard-coded levels or times into Macros 21-24.

## 16. Automated Studio One Recovery (October 2026)

### Scheduled Restarts
Windows Task Scheduler runs RestartStudioOne.ps1 daily at 6:00 AM and 6:00 PM.
Task: MushroomForest_StudioOne_Restart

### Freeze Watchdog
Watchdog/WatchStudioOne.ps1 checks Studio One every five minutes.
HEALTHY: No action.
FROZEN: Two consecutive unresponsive checks trigger recovery.
NOT_RUNNING: Recovery starts immediately.
A 15-minute cooldown prevents repeated watchdog restarts.
A mutex prevents overlapping restart operations.
Task: MushroomForest_StudioOne_Watchdog

### Restart Procedure
RestartStudioOne.ps1 requests a graceful shutdown and selects No when asked to save.
If Studio One does not close within 15 seconds, it is forcibly terminated.
StartStudioOne.ps1 launches the golden song, handles crash recovery, and sends Transport Start.
Recovery verifies the process is responding and the correct song is loaded.
IMPORTANT: Automatic restarts must NEVER save the golden Studio One song.

### Logging
Watchdog/RestartLog.csv records restart time, reason, initial state, shutdown method, result, and duration.
Watchdog/WatchdogLog.csv records five-minute health checks and recovery actions.
Watchdog/FrozenCount.txt stores consecutive failed checks.
Watchdog/LastWatchdogRestart.txt stores the cooldown timestamp.
Logs and temporary state files are excluded from Git.

### Viewing Logs
Import-Csv ".\Watchdog\RestartLog.csv" | Format-Table -AutoSize
Import-Csv ".\Watchdog\WatchdogLog.csv" | Group-Object State,Action | Select-Object Count,Name

### Limitations
Startup transport movement is now verified (see section 18); audible output is not independently verified.
grandMA2 is not yet included in scheduled restarts.
GUI automation requires an interactive Windows session.
Unattended freeze recovery and full Windows reboot recovery still need testing.

## 17. Prepared Ordered Startup and grandMA2 Monitoring (October 14, 2026)

These scripts are prepared for review and isolated testing, not deployed to
Windows Startup or Task Scheduler. The current independent Studio One and
grandMA2 Startup shortcuts are unchanged, so cold-start ordering remains unverified.

`StartMushroomForest.ps1` runs the existing `StartStudioOne.ps1`, including its
Transport Start shortcut, verifies a responsive process displaying the golden
song name, and then calls the grandMA2 launcher. It shares the existing Studio
One restart mutex to prevent overlapping watchdog recovery during ordered startup.

`StartGrandMA2.ps1` requires Studio One readiness and launches the installed
`grandMA2 onPC 3.9.60.28\gma2onpc.exe` with `-s:mushroom_forest_current`.
This requests the existing live show in the version-specific ProgramData shows
directory, not the repository checkpoint. A running grandMA2 is left untouched.
The launcher checks process/window readiness but does not independently verify
the loaded show, MIDI, audible playback, or Executor 106.

Plugin 2 remains unchanged and owns audio-level initialization, its startup delay,
CC53 Transport Start, and Executor 106. PowerShell does not send additional MIDI,
invoke `Mushroom.Startup()`, or start/reset executors. Studio One keeps its own
Transport Start during all startup and recovery paths.

The user-approved live shutdown test on October 14 established a credential-free
local method: `Get-Process gma2onpc`, `CloseMainWindow()`, and one Return posted
directly to grandMA2's window with Win32 `PostMessage` (WM_KEYDOWN/WM_KEYUP).
The shutdown dialog appeared with Do not Save selected. The application exited
gracefully and the live show's SHA-256 hash remained
`AE8D82D49D77F170C2D79A871243D5D8A64292DF574C691E097FF671F5B10911`.
Foreground activation was unreliable; direct window targeting worked.

`StopGrandMA2.ps1` now implements that sequence with extra verification. It
checks executable, process and window identity, requests normal close once, and
compares the visible shutdown prompt and selected Do not Save button with the
reviewed image `assets/grandma2-shutdown-do-not-save.png`. The image's SHA-256 is
pinned in configuration. It checks again immediately before posting one Return.
The screen-copy capture failed in the full-script test because PowerShell covered
the buttons. It now uses Win32 PrintWindow to capture grandMA2 independently of
overlapping windows. The reference was trimmed to exclude a desktop-window shadow;
the prompt and selected Do not Save button retain exact pixel verification.
This calibration requires the tested 1809 x 1100 window and display scale; a
changed layout, selection, failed window capture or missing reference refuses Return
and may leave the dialog open. Do not interact with the dialog during shutdown.
No command-line textbox, login credentials, focus stealing, coordinate clicks,
save commands, or forced termination are used. A successful shutdown must also
leave the live show's hash unchanged; a mismatch is logged without restoring or
overwriting the file. This verifies a change after the fact; it does not disable
any independently configured autosave. The complete guarded script still needs
an approved live test; only the underlying close-and-Return sequence is live-tested.

`Watchdog/WatchInstallation.ps1` writes grandMA2 observations to the ignored
`Watchdog/GrandMA2HealthLog.csv`. States are NOT_RUNNING, RESPONSIVE,
UNRESPONSIVE, NO_MAIN_WINDOW, and MULTIPLE_PROCESSES; every action is LOG_ONLY.
Responsiveness is the Windows process indication, not a full show-health test.
Monitoring runs before the optional unchanged Studio One watchdog, so Studio One's
mutex skip does not suppress grandMA2 observations. A monitoring/logging failure
does not prevent Studio One watchdog execution when that option is enabled.

`Watchdog/InstallationLog.csv` records startup/shutdown results and durations.
Both new log paths are already ignored. Startup/shutdown scripts default to
plan-only output; `-Execute` enables actions and shutdown requires confirmation.
Do not use them against the running installation without explicit approval.

There are no scheduled grandMA2 restarts or automatic grandMA2 freeze recoveries.
Deployment still requires an approved live test of the complete guarded
startup/shutdown scripts and a separately approved replacement of the independent
Startup shortcuts. Existing Studio One scheduled recovery remains unchanged.

### Full-script live test findings

The October 14 ordered startup completed at 19:36:15 in 12.7 seconds. Studio One
was responsive with the golden song, and grandMA2's screen showed Daily Cycle at
Day. A later capture showed the sequence progressing to Rainbow. This is evidence
of executor startup; audible playback and all MIDI levels still need confirmation.

At 19:36:21 the live grandMA2 show was written: its size changed from 227476 to
230125 bytes and its SHA-256 changed to
`1161BF0DFFAE626CAA51560D64B2FFF28AEB2B476F2FF4D195A534CD91DE7343`.
This preceded the 19:37 shutdown attempt, which sent no Return. Plugin 2 was
inspected read-only from the compressed show; its Lua contains no save command.
The startup write's cause remains unresolved, so do not repeat or deploy the
`-s:mushroom_forest_current` startup path until no-save behavior is established.
No-save applies even to metadata or benign runtime changes.

The pre-test native `.backup` matched the original live-show hash and was copied
to Windows TEMP outside Git. No live show was restored or overwritten by the
scripts. Studio One's golden song hash remained unchanged. The user cancelled
the pending shutdown dialog and both applications remained running.

## 18. Studio One Playback Verification (October 15, 2026)

The user found Studio One running but stopped after scheduled recovery. The last
24-hour review showed successful graceful scheduled restarts at October 14 18:00
(21.8 seconds) and October 15 06:00 (19.0 seconds), with 288 healthy watchdog
checks and no automatic freeze recoveries. These success checks only established
process responsiveness and the expected song window, not playback.

Live testing reproduced a foreground-focus failure: WScript.Shell.AppActivate
returned True while Windows Terminal remained foreground after the two-second
wait. The keyboard binding Ctrl+Alt+F9 was correctly assigned to Transport Start,
but the script could deliver that shortcut to the wrong application and still
report success. This demonstrates a failure mechanism, not proof of what happened
during either past scheduled restart.

`StartStudioOne.ps1` now imports `StudioOnePlayback.ps1` after the existing launch
and crash-dialog handling. The helper verifies the executable, golden song title,
window ownership, visibility, enabled state and calibrated dimensions. PrintWindow
captures Studio One independently of foreground windows. Four pinned reference
images in `assets/studioone-play-*.png` identify focused/unfocused playing and
stopped appearances. Unknown controls/layouts fail without input.

When verified stopped, Start is sent with WM_LBUTTONDOWN/WM_LBUTTONUP directly to
the identified Play control using window-to-client coordinate conversion. No
global SendKeys, focus activation, save commands, or restarts are used by the
helper. It rechecks window identity and control state immediately before input,
and does not click an already-playing control. At most two Start attempts are made.

Success requires a recognized playing indicator and changes in the transport
time display across three samples one second apart, on the same process/window.
Playback failure throws and exits startup unsuccessfully. The unchanged
`RestartStudioOne.ps1` already uses the child exit code, so a playback failure
becomes FAILED in RestartLog.csv even if the process is responding. The ignored
`Watchdog/PlaybackLog.csv` records STARTED_AND_VERIFIED,
ALREADY_PLAYING_VERIFIED, or PLAYBACK_FAILED, command count, duration and detail.

The guarded transport calibration currently requires a 1936 x 1048 window at the
tested display scale. Window movement/overlap is supported; resizing, minimizing,
theme/scale changes or an unrecognized UI must fail clearly rather than guess.
Transport movement does not prove audible output. Regular five-minute watchdog
checks remain process-only; they do not automatically resume playback stopped
after startup.

Twenty-one isolated tests cover retries, stalled clocks, changed windows,
reference integrity, failure logging and propagation to restart results. A live
candidate test verified stopped transport, started it, and verified subsequent
movement; both application process IDs and the golden-song/live-show hashes
remained unchanged. Working scripts were backed up to ignored files before changes.
The installed startup script now uses this helper for future scheduled and
watchdog recoveries. Task definitions, grandMA2 and Plugin 2 were not changed.

### October 16 scheduled-startup failures and correction

The October 15 18:00 and October 16 06:00 scheduled restarts logged FAILED
(16.6 and 16.8 seconds). Each playback entry recorded zero Start commands because
window verification failed. Explicit window enumeration found the correct song
window while .NET MainWindowHandle identified an untitled auxiliary window.
A later read-only check also found the actual song window minimized. These are
verified failure mechanisms; the logs do not record the minimized state at the
time of either restart.

Startup readiness, playback targeting, and restart result checks now resolve the
visible, enabled CCL golden-song window belonging to the expected executable.
Before playback verification, startup requests restoration of that window if
minimized or resized, waits up to five seconds, and refuses Play unless the reviewed dimensions return.
The existing exact layout/control checks, bounded Start attempts, advancing-clock
verification, and failure logging remain required. Scheduled and watchdog
recovery both invoke the same startup script; ordered startup also uses it.

All 30 isolated playback tests and 26 installation-control scenarios pass.
The approved October 16 live test initially found normal-size restoration insufficient (1920 x 1032). Explicit maximization restored the reviewed 1936 x 1048 layout and exact Play control recognition. The helper now maximizes the verified song window when minimized or outside the calibrated size, then retains all strict layout and image checks.
A repeated live test began STOPPED, minimized the window, and ran the corrected helper: STARTED_AND_VERIFIED with one Start command. A follow-up returned ALREADY_PLAYING_VERIFIED with zero commands. Both application PIDs and golden-song/live-show hashes were unchanged. No application was restarted; tasks remain unchanged. A full scheduled restart with this correction remains unverified.

## 19. Water lighting correction (October 19, 2026; saved live, not committed)

The intended water lighting is continuous normal water animation outside Rainbow,
with Rainbow temporarily overriding the colors. This concerns the lighting,
not Studio One's Water audio track or MIDI CC49.

Read-only inspection and XML exports established:

- Group 1, Water, contains fixtures 101 through 250 (150 fixtures).
- Effect 1, Water, supplies DIM and RGB effect references: 600 attributes.
- Daily Cycle is Sequence 2 on Executor 1.106. Day Cue 1 runs
  `Go Executor 111`. Rainbow Cue 1.2 starts Executor 113. Rainbow Off Cue 1.3
  runs `Off Executor 113 ; Go Executor 111`.
- Executor 111 is Sequence 1, Day; its cue has no Water-group content.
- Executor 113 is Sequence 12, Rainbow; its water color effect is
  Effect 7, RGB Rainbow.
- Before this correction, Sequence 2 stored the normal Water effect only at
  Dusk Cue 2, with no Water entries at Day, Rainbow Off, or New Day.

The user explicitly authorized adding the existing Water effect to Sequence 2
Cues 1, 1.3, and 1.4, testing the normal running cycle, and leaving the show
unsaved. Cue data, Group 1, Effect 1, and the existing on-disk show were backed
up outside Git in Windows TEMP before editing.

The edit used the separate BlindEdit programmer, Group 1, and `At Effect 1`,
then effect-only merges into the three cues. Reapplying the effect separately
before each later merge was necessary to create explicit stored entries.
The BlindEdit programmer was cleared before returning to Live; the Live
programmer was not cleared. No Go, Goto, transport, restart, or SaveShow
commands were issued.

The resulting Sequence 2 export was checked against the original: exactly
600 original Water effect references were added to each of the three cues
(1,800 total). Removing only those additions reproduces the original sequence
XML exactly, including all other fixture data, cue commands, timings, and
sequence settings.

A read-only live-output monitor sampled all 150 exported RGB patch addresses
360 times from 19:17:49 to 19:24:27 local time. It covered all eight phases,
including the next full Rainbow phase and the return to normal water afterward.
Every fixture had nonzero combined RGB output in every sample; all 150 fixtures
were observed changing output in each phase. The next Rainbow showed the
expected saturated RGB cycling, while Rainbow Off and New Day returned to the
normal Water palette without blackouts. The monitor completed and exited.
This verifies grandMA2's calculated DMX output, not physical delivery or light
emission. The user could not confirm the result through the camera.

The edit initially remained unsaved, with the live show file at SHA-256
`681BF0A6E714CA60A52DE73E6B7D5F8B2A4366352E886687396A1FD3E536DB44`.
The user then explicitly authorized saving the live show so the fix would
survive a restart, while withholding any Git commit until an in-person check.
At approximately 19:30 local time, a one-time
`SaveShow "mushroom_forest_current" /noconfirm` on internal Drive 1 saved the
live show. Its new SHA-256 is
`B4E82CB28B065F5F094B3F5587DBE9BE8250126734B5DDEF3AF069437BADE720`.
This was an explicitly requested manual save, not a recovery-script change.
No automatic saving was added; neither application was restarted.

The pre-save show and verification artifacts were preserved outside Git at
`C:\Users\Mushroom Forrest\Documents\MushroomForestBackups\20261019-193013-water-fix`,
with `save-verification.json` recording the old/new hashes. The repository
grandMA2 checkpoint was not updated, and nothing was committed or pushed.
On October 20 the user confirmed that the physical water feature looks good.
Explicit commit permission is still required; nothing has been committed or pushed.

Verification artifacts in Windows TEMP include
`water_before_20261019_1930.xml`, `water_verified_after_20261019.xml`,
`water_group_before_20261019.xml`, `water_effect_before_20261019.xml`,
`water_show_before_20261019.show.gz`, `water_change_verification_20261019.json`,
`water_cycle_20261019.csv`, and `water_cycle_summary_20261019.json`.
These are not Git artifacts.

## 20. Mushroom touch period selection (October 20, 2026; subsequently saved in section 23)

The user authorized changing mushroom selections to enter the matching period
in the running daily sequence, apply matching sound, and continue the normal
timed cycle. Day must always enter the first Day, Cue 1. The user also requested
MIDI-device persistence, and asked that work continue while they were away.

### MIDI routing and persistence

Windows port enumeration before connection showed LoopBe Internal MIDI and Studio
1810c MIDI In/Out. Connecting the controller added QT Py RP2040 input/output
ports without changing LoopBe's indices during this connection. The initial
grandMA2 Options/MIDI dialog used LoopBe for both input and output. With explicit
permission, input was changed to QT Py RP2040; output stayed on LoopBe. The user
confirmed touch operation afterward. Studio One's saved control-surface and
keyboard receive ports still point to LoopBe.

Read-only registry inspection verified that grandMA2 has already persisted:

```text
HKCU\Software\MA Lighting Technologies\grandMA2 onPC\Settings\Midi
MidiInDeviceId   = 2
MidiInDeviceName = QT Py RP2040
MidiOutDeviceId  = 1
MidiOutDeviceName= LoopBe Internal MIDI
```

These are per-user onPC preferences, separate from the live show and the
`gma2_midiconfig` file (which contains MIDI channel/MSC settings). No registry
write, restart, task modification, or show save was needed for this finding.
A restart with the new selections, enumeration during reboot, and behavior when
the controller is absent remain untested. Connect the controller before launching
grandMA2. No new startup automation has been deployed.

### Cause of the audio mismatch and changed behavior

The original MIDI remote map was five notes (48–52) triggering Executors
101–105. Their behavior was mixed: Day and Night jumped into the daily cycle,
Dark Mode and Rainbow launched separate lighting executors, and Thunderstorm
triggered the lighting sequence without selecting its daily-cycle period.
Plugin 2's old two-track fades also assumed fixed starting levels and could
leave an unrelated environmental track audible. Studio One's CC50 control was
inspected at 39.37% (50/127) while other periods were selected, confirming a
retained Night level; this was not an audible-output measurement.

The observed five sensor notes now select:

| MIDI note | Period | Sequence 2 cue | Touch macro |
|---:|---|---|---:|
| 48 | First Day | 1 | 25 |
| 49 | Dusk (previously Dark Mode) | 2 | 26 |
| 50 | Night / Evening | 3 | 27 |
| 51 | Rainbow | 1.2 | 28 |
| 52 | Thunderstorm | 1.1 | 29 |

No sixth sensor/Dawn note was present in the existing map. The proposed use of
the former Dark Mode sensor for Dusk was sent to the user for optional
clarification; no alternative mapping has been supplied. Dawn remains Cue 4
in the automatic cycle and is supported by `Mushroom.SelectPeriod('dawn')`.

`grandMA2/MushroomControl.lua` and its import descriptor are now readable source
for Plugin 2. `M.CONFIG.touch` contains the two-second touch fade, a 0.5-second
same-period debounce, the fully qualified daily executor, and the note map.
`M.CONFIG.periods` contains cue, target audio, and auxiliary-lighting assignments.
The existing levels, startup delay, normal thunderstorm/rainbow fades, and
40-second development cue trigger settings are preserved.

Remote commands launch Macro 25–29; those call `Mushroom.SelectNote(note)`.
`SelectPeriod` uses `Goto Cue ... Executor 1.106 Fade 2`. Each daily cue launches
its own Macro 30–37, calling `Mushroom.OnCue(period)`. These launchers contain no
levels or timing configuration. Existing Macro 21–24 remain unchanged and usable.

`OnCue` releases obsolete legacy/auxiliary lighting playbacks, retains the
target overlay, and applies the complete environmental audio target. It refuses
a delayed callback whose period no longer matches the active daily cue. Audio
fades use the last CC levels sent by Plugin 2 and a generation counter so a newer
transition cancels older writes. All four environmental tracks participate;
unwanted tracks reach zero, and Water remains at the configured level 45.
MIDI updates omit unchanged intermediate values and reassert all four endpoints.
Old in-flight fades without a generation token cannot write after the hot update.

Normal Thunderstorm and Rainbow retain their configured 10-second audio fades;
normal Dusk and Dawn retain the existing cue-duration audio fade. Touching Dusk
or Dawn reaches that period's target audio in two seconds; the sequence then
continues its normal cue timing. Other cue boundaries use a configured
two-second correction if an audio mismatch remains. A separate Lua day-cycle
timer was not introduced.

### Preservation, verification, and remaining work

The pre-change on-disk show and documentation backups are outside Git at:

```text
C:\Users\Mushroom Forrest\AppData\Local\Temp\MushroomForest-touch-before-20261020-171313
```

The baseline live-show SHA-256 was
`3221CABD9ADB7F7C586ED14D34E3BD38A4BA7D5D3A6052730AA540F386130DFE`.
This differs from the October 19 save; the file was already dated October 20
14:10:06 before this work. Its intervening write has not been attributed to a
cause, and no automatic restoration or overwrite was performed.

Original Plugin 2 Lua/XML, Sequence 2, all relevant sequences/executors, MIDI
remotes, and Macro 21–24 were exported into Windows TEMP before editing.
Exact post-change XML comparison verified eight cue-command replacements only:
all fixture/effect data (including the approved Water fix), timings, and sequence
settings remained unchanged. All five MIDI note mappings and thirteen new macro
commands were exported and checked. Plugin 2's initial updated stored source was
exported and compared to the tested source. The final v2 delayed-callback guard
was then tested and imported. On October 21, Plugin 2 was exported again and
its stored v2 source matched `grandMA2/MushroomControl.lua`. Startup was not
called during the definition-only hot update;
its existing `started` guard and separate CC53 startup pulse remain.

`tests/TestMushroomControl.lua` passed 80 isolated scenarios in grandMA2's Lua 5.3
interpreter. Each candidate runs in a separate Lua environment with simulated
MIDI, executors, clock, and startup; it does not replace the live Mushroom table.
Coverage includes all 64 period-to-period combinations, automatic continuation,
rapid changes, stale writes/callbacks, debounce, arbitrary starting audio mixtures,
note dispatch, first-Day selection, and preservation of the startup pulse.

Live short-command checks passed for Night, Thunderstorm, Rainbow, Dusk, Dawn,
and first Day, plus rapid interrupted selections ending at Rainbow. Each check
verified the selected daily cue, period callback, and all four outgoing audio
levels. Additional incoming sensor notes had overridden early test selections.
A long-running parent Lua test also failed a callback check; successful live
verification used separate short selection and sampling commands. Importing the
plugin replaced the temporary test filter, so the filter was reinstalled after
import and its identity was checked during controlled observation.

An independent `gma.timer` observation completed 340 samples over 362.891 seconds.
After a Day selection, it observed the automatic order Day, Thunderstorm, Rainbow,
Rainbow Off, New Day, Dusk, Night, Dawn, Day, and into Thunderstorm again.
The audio trace showed the normal configured transitions. All 150 Water fixtures
had nonzero combined RGB output in every sample; every phase included a sample
where all 150 changed output. Water audio remained at 45. Stable cue/callback
states matched; two multi-call snapshots straddled a cue boundary, recorded
explicitly in the summary rather than treated as atomic observations.

The controlled test recorded zero verification failures. It temporarily filtered
70 sensor selections, then restored a clean, unfiltered note dispatcher. The
filter had a bounded expiry as an additional fallback. No test timer continues
sampling. This verifies calculated DMX and outgoing MIDI state; physical sound,
the appearance of the transitions, and the final physical sensor experience
still require the user's check. Extra incoming notes may represent actual
touches; they were not diagnosed as a sensor hardware fault.

Evidence remains outside Git in Windows TEMP: `touch_tests_20261020.txt`,
`touch_live_separate_20261020.txt`, `touch_separate_cycle_20261020.csv`,
`touch_cycle_summary_20261020.json`, the before/after exports, and preserved early
test traces. The final summary records zero Water blackouts and restored input.

The live show remains unsaved. A separately authorized manual show save is
required to preserve these in-memory show changes across grandMA2 restarts.
The repository `.show.gz` checkpoint remains unchanged. No commit or push has
been performed. The existing scheduled Studio One restart ran at 18:00 and
logged success; Codex did not initiate it or change the schedule. No application
restart, forced termination, Windows reboot, or playback-stop command was issued
as part of this work.

## 21. Unattended mushroom selections (October 21, 2026; diagnosis in progress)

The user reported repeated, very short Day/Thunderstorm/Rainbow/Dusk periods
without anyone touching the mushrooms, with missing thunderstorm lightning.
Do not treat October 20's controlled cycle test as validation of untouched,
input-enabled operation: it temporarily filtered 70 incoming selections.

Read-only exports confirmed that Sequence 2 still has the same eight Time
triggers at 40 seconds, and that Plugin 2's live configuration has all eight
`CONFIG.timing` entries at 40. Startup copies that table into stored cue timers;
the running sequence subsequently uses those timers. The table and stored
timers agree. Macro 21–37, executor assignments/options, and Sequence 7's
thunderstorm lighting were checked against the previously exported state.

A separate shared WinMM input observer captured native USB messages directly
from QT Py RP2040, without taking over grandMA2's MIDI connection. A five-minute
capture recorded 62 messages: 31 Note On selections, each followed by its
10-ms Note Off pulse. The user reported no touches. Examples are note 52 at
12:49:07 and 12:49:31, followed by note 48 at 12:49:40 local time. Matching
grandMA2 selection calls were logged at the same times. This establishes
unwanted controller input, rather than inferring it from cue changes alone.

A separate six-minute passive Lua trace (12:56:46–13:02:46) recorded 31 selection
requests and 29 cue callbacks; every callback followed a matching selection
request within one second. Callbacks included 11 Thunderstorm, 11 Day, five
Dusk, and two Night entries. This trace found no unexplained internal cue
callbacks. Two selections did not produce callbacks, consistent with the
existing same-period debounce. Its SelectPeriod/OnCue wrappers automatically
removed themselves when sampling finished. The earlier passive SelectNote
logger still needs explicit removal when diagnosis finishes. No input-isolation
test has been run today; permission was requested but not yet supplied.

The user supplied `mush_touch_v1/mush_touch_v1.ino`, an MPR121/QT Py RP2040
controller using electrodes 1–5 and MIDI notes 48–52. The original sent a
selection on a single touched sample and rearmed after a single released
sample. Its 10-ms Note Off is a fixed pulse, not a measurement of how long the
electrode was touched. Short MIDI pulses alone therefore do not establish
the duration or electrical cause of the sensor interference.

The source now uses `TouchFilter.h`: 120 ms continuously touched to select,
250 ms continuously released to rearm, and 500 ms released before first arming
after startup. Held touches select once. Each sensor filters independently;
timing uses unsigned subtraction across millis rollover. Note assignments,
velocity, channel, sensitivity thresholds, and auto-configuration settings
are unchanged. Baseline debugging now reads electrodes 1–5, matching sensing.
Six compile-time scenarios in `tests/TestMushroomTouchFilter.cpp` passed with
the RP2040 C++ compiler. The full firmware build also passed using Arduino CLI
1.5.1, RP2040 core 6.3.0, Adafruit TinyUSB 3.7.7, MIDI Library 5.0.2,
MPR121 1.2.1, and BusIO 1.17.4. Build options select Adafruit QT Py RP2040,
TinyUSB, and a standard 125 MHz clock. Temporary compiler data was moved to
`TEMP/mf21deb/d` to resolve the original tool-path build failure.
The final build uses 86,300 bytes of program space and 17,404 bytes of RAM.
The UF2 SHA-256 is
`FE14C7B914365E58A554B8AF155BF6ADB13AE84E30235B17B01745DED415BB85`.
The built filter was compared with the tested source after removing Arduino's
generated line directive; source and firmware hashes are recorded in TEMP.

Windows identifies the connected controller as COM5, VID 239A/PID CAFE,
serial DF625857834B4A26. Guarded upload attempts around 13:20 and again after
the user's explicit retry request around 14:24 both identified the correct
board but failed entering the bootloader: `No drive to deploy.` No firmware
was transferred by those attempts. After the user unplugged/reconnected it,
Windows still enumerated COM5. Deployment was subsequently completed by the
user through Arduino IDE, as described below.
The user subsequently uploaded through Arduino IDE on another connection and
reconnected the controller. The first upload enumerated as XIAO RP2040; neither
of two test touches produced MIDI. Local board definitions show QT Py Wire1 on
GPIO 22/23, whereas the XIAO variant defaults both Wire1 pins to 31. The user
then recompiled for QT Py and reconnected it. Windows again enumerated
QT Py RP2040; two held touches produced exactly two note-50 selections.
All five note numbers were subsequently captured during the user's tests.
Debouncing may reject short interference but does not establish or repair
the underlying electrical cause of sustained false touches.

The original sketch backup and diagnostic CSV/XML/JSON files are in Windows
TEMP, including `mush_touch_v1.before-filter-20261021.ino`,
`touch_raw_midi_long_20261021.csv`, `touch_full_audit_20261021.csv`, and
`touch_full_audit_summary_20261021.json`. Portable Arduino tools and all build
artifacts are also outside Git in TEMP. No scheduled tasks or app restarts
were initiated, and no show or song was saved.

The user additionally requested visible feedback on intentional or accidental
triggers. A live patch/group export identifies Group 3, Control Mushrooms, as
fixtures 1101–1105. The overlay and corrected physical correspondence were
subsequently implemented and confirmed by the user; see section 22.
Missing sound-reactive lightning remains unresolved; unchanged stored effect
data does not establish a working sound-input signal or physical output.

## 22. MIDI reconnect and confirmation flashes (October 21; subsequently saved in section 23)

Following the corrected firmware upload, Windows received touch MIDI but
grandMA2 did not: its passive note log still ended at 14:18. The open Options
dialog retained the previous XIAO device label. Input was set to None, Options
closed and reopened, and the refreshed list showed QT Py RP2040. Selecting it
restored live reception without restarting grandMA2 or Windows; output remained
LoopBe Internal MIDI. The user's second all-five pass at 15:03:50–15:04:08
matched note 50, 48, 49, 52, and 51 at both the raw USB monitor and grandMA2.
The user reported all controls working. This validates the reconnect procedure
for this connection; other disconnection/reboot conditions remain untested.

The six-minute post-filter log contains 40 MIDI messages (20 selections plus
their fixed Note Off pulses), while the user was still intentionally testing.
The user confirmed that testing, then stopped. Its final 3 minutes 45 seconds
contained no further MIDI selections, ending about 15:12:12. Do not describe
the entire six minutes as untouched or claim that sustained interference is
impossible. Evidence: `touch_all_five_midi_20261021.csv` and
`touch_quiet_post_filter_20261021.csv` in TEMP.

The user requested visible confirmation for intentional or accidental triggers
and explicitly approved a live five-flash check. Plugin 2 source is now
`2026-10-21-touch-v3`. `CONFIG.touch.feedback` holds the following final mapping:

| Note | Period | Fixture | Sequence | Executor |
|---:|---|---:|---:|---|
| 48 | First Day | 1102 | 1001 | 1.201 |
| 49 | Dusk | 1101 | 1002 | 1.202 |
| 50 | Night | 1104 | 1003 | 1.203 |
| 51 | Rainbow | 1105 | 1004 | 1.204 |
| 52 | Thunderstorm | 1103 | 1005 | 1.205 |

These slots were
checked before use; the two existing empty executor objects had no assignment.
The original Plugin 2 and empty-executor exports are in TEMP.

`MushroomTouchFeedback.xml` contains five single-fixture white cues, each with
Dimmer/R/G/B at 100, with no cue commands, effects, or timed progression. The
five new executors use Super priority. The main daily Sequence 2 export is
exactly unchanged apart from its export Info timestamp. Stored Plugin 2 source
was exported and compared with the tested v3 source. Existing Macros 21–37,
remote note assignments, and the original auxiliary executors were not edited.

On a touch, OnCue starts its normal scene overlay first, then the corresponding
feedback overlay with a 0.05-second attack. A bounded one-shot timer releases it
after 0.4 seconds with a 0.35-second fade. Natural cue continuation does not
flash. A same-period request suppressed by Lua's debounce still flashes as an
incoming trigger. Per-note generation counters prevent older release timers
from cancelling a newer flash. Resource guards refuse missing or reassigned
feedback executors. Releasing the overlay returns control to the current scene;
it does not write a remembered color back over a newer period.

Definition-only reload now preserves a compatible in-flight audio fade;
starting a new transition remains the operation that cancels old generations.
The original no-generation stale-write rejection remains in SendCC. All 86
isolated Lua tests passed, including the original 80 cases plus feedback
mapping/release, retrigger cancellation, missing/reassigned resources, natural
continuation, independent sensors, and reload during an audio fade. No live
startup entry point was invoked by the installer. M.started remained true.
The v3 dispatcher replaced the earlier passive v2 note wrapper, and its saved
original-function field was cleared.

The approved manual test flashed notes 48–52 at about 15:21:21, :24, :27, :30,
and :33, temporarily holding each for 1.1 seconds for visibility. The normal
0.4-second setting was immediately restored after scheduling each flash.
Calculated DMX was nonzero on each target during its flash and its feedback
executor was released by the later sample. The user identified the physical
order as Dusk, Day, Thunderstorm, Night, Rainbow, revealing that fixture order
did not match MIDI note order. The five feedback cues and Plugin 2 mapping were
corrected to the table above. All 86 isolated tests passed again, and the final
sequence exports verified each fixture assignment. The user subsequently
confirmed that the flashes are correct and sequencing appears correct. This is
physical confirmation from the user, not a new instrumented full-cycle test.
The test timer ended after 150 callbacks. Evidence includes
`touch_feedback_flash_test_20261021.csv`, `touch_feedback_tests_20261021.txt`,
and the before/after XML/Lua exports in TEMP. No flash resources are intended
to remain active after the one-shot release.

The live show file still has SHA-256
`3221CABD9ADB7F7C586ED14D34E3BD38A4BA7D5D3A6052730AA540F386130DFE`.
These in-memory show changes remain unsaved. No show save, song save,
application restart, scheduled-task change, commit, or push was performed.
The user confirmed thunderstorm audio, then clarified that all storm behavior
appears correct except the sound response. The soundtrack contains varying
amounts of thunder; a response during clearly loud thunder has not been verified.
Sound-reactive lightning remains unresolved;
correct sequencing and confirmation flashes do not verify the storm effect or
its audio-input path. The earlier greenish ceiling-edge tint at low sound levels
also has no established cause or verified correction.

### Persistence and operating notes

- The user uploaded the filtered firmware for Adafruit QT Py RP2040; board flash
  retains firmware across power cycles. Keep `TouchFilter.h` beside the sketch.
- The 120-ms sensor filter rejects short interference, requires 250 ms released
  to rearm, and requires 500 ms released at startup. It cannot reject every
  sustained false touch. The separate 0.5-second Lua debounce suppresses repeated
  requests for the same period; it is not an electrical noise filter.
- A white flash identifies a MIDI selection that reached Plugin 2, including an
  accidental trigger that passed the firmware filter. Rejected sensor glitches
  do not emit MIDI and therefore cannot produce a confirmation flash.
- MIDI device preferences are stored separately from the show. After reconnect,
  use Options → MIDI → MIDI In Device → None, close and reopen Options, then
  select QT Py RP2040. Preserve LoopBe Internal MIDI as output. This procedure
  was verified without restarting grandMA2 or Windows; cold boot remains untested.
- Plugin 2, cue macro changes, and feedback sequences/executors still need a
  separately authorized manual show save to survive restarting grandMA2. The
  repository show checkpoint is unchanged. Updating documentation does not save
  the running show, commit files, or authorize a restart.

## 23. Authorized saved checkpoint before thunder editing (October 21, 2026)

The user explicitly requested saving the Studio One song, grandMA2 show,
new mushroom touch code, and documentation, then committing and pushing them
before any further thunder editing. This supersedes the unsaved status in the
historical sections above. It authorizes this manual checkpoint only; recovery
must still never save the golden song, and future live saves require permission.

- Studio One's verified `Mushroom Forest Sound_Current` window was saved with
  foreground-checked Ctrl+S at about 16:02. Its unsaved-title marker disappeared.
- grandMA2's keyboard-focus guard refused the command-line save attempts without
  typing a command. The owned Backup panel's verified Save Show button then saved
  `mushroom_forest_current` at 16:06:12. Auto Save remained Off.
- The saved live show was copied to `grandMA2/mushroom_forest_current.show.gz`;
  SHA-256 comparison confirmed an exact match.
- The checkpoint includes the golden Studio One song, saved show, Plugin 2 Lua
  and import descriptor, touch macros/feedback XML, QT Py sketch and filter,
  the two touch test sources, README, this document, and AGENTS.md. Existing
  unchanged audio media remains in Git LFS. No thunder clip was trimmed, moved,
  replaced, or synthesized before this checkpoint.
- The final mapped Plugin 2 export matched repository source. Existing validation
  is 86 passing isolated Lua scenarios, six passing compile-time filter scenarios,
  a complete RP2040 firmware build, verified show-copy hashes, and the user's
  physical confirmation of flashes and sequencing. No restart/reload persistence
  test was performed, and sound-reactive lightning is not yet verified.
- No application was restarted and playback was not intentionally stopped.
  Scheduled tasks and automatic recovery behavior were not changed.

Saved file SHA-256 values:

| File | SHA-256 |
|---|---|
| Live show and repository checkpoint | `C3DBE69F6C1CD8A17748A7F62D92289F3E533D460B46F5CC3FF231705F1C3AA5` |
| Golden Studio One song | `70DD144B577700CB8001E042BA0ED19E31BD5963FA0DB96526A8E2F3B5F16B79` |

Pre-save song/show copies, the previous repository show, documentation backups,
and `save-verification.json` are outside Git in Windows TEMP under
`MushroomForest-checkpoint-20261021-155306`. Logs, firmware builds, and diagnostic
captures remain outside this checkpoint. The commit ID and remote push are
reported after Git verifies them; this document does not embed its own commit ID.

