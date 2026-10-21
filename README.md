# Mushroom Forest

Lighting and sound control system using grandMA2 onPC and PreSonus Studio One.

## Documentation
See [Current System State](docs/mushroom_forest_current_state.md) for architecture, MIDI assignments, configuration, and recovery procedures.

## Automated Studio One Recovery
Studio One restarts automatically at 6:00 AM and 6:00 PM daily.
A watchdog checks Studio One every five minutes and attempts recovery if it freezes or stops running.

## Scripts
- StartStudioOne.ps1: Opens the golden song and starts playback.
- RestartStudioOne.ps1: Restarts Studio One without saving changes.
- Watchdog/WatchStudioOne.ps1: Detects freezes and initiates recovery.
- Watchdog/RestartLogging.ps1: Records restart results.

## Logs
- Watchdog/RestartLog.csv: Restart history and recovery results.
- Watchdog/WatchdogLog.csv: Five-minute health history.
- Watchdog/PlaybackLog.csv: Verified transport-start results and playback failures.

Studio One startup now targets its own Play control instead of relying on
foreground keyboard focus. It recognizes reviewed playing/stopped control images
and requires an advancing transport across three samples before reporting success.
A playback failure makes startup exit unsuccessfully, so restart cannot report
`SUCCESS` merely because the song window opened. Start retries are bounded to two.
Already-playing transport is verified without clicking Play again.
Startup now locates the actual golden-song window instead of relying on
Process.MainWindowHandle, and requests maximization to the reviewed layout when that window is minimized or resized
before inspecting Play. A failed restore is logged without blind input.

The current transport calibration supports a 1936 x 1048 Studio One window at
the tested scale; moving or covering that window is supported, but an unknown
size/control appearance fails safely. Keep the reviewed `assets/studioone-play-*.png`
files with `StudioOnePlayback.ps1`. The regular watchdog remains a process-health
check; startup transport verification does not independently verify audible output.

## Important
Automatic restarts must NEVER save changes to the golden Studio One song.
Logs, temporary state files, and backup scripts are excluded from Git.
grandMA2 is not yet included in scheduled restarts.

## Mushroom touch controls (October 21, saved checkpoint)

`grandMA2/MushroomControl.lua` is the readable Plugin 2 source. Touch selections
now enter Sequence 2 on Executor 1.106, including its audio state, then continue
the normal timed cycle. Day always selects Cue 1. The five existing sensor notes
are Day (48), Dusk (49, formerly Dark Mode), Night (50), Rainbow (51), and
Thunderstorm (52). There is no separate Dawn sensor in the observed MIDI map.

Touch fades use `M.CONFIG.touch.fade` (currently two seconds). Audio fades begin
at the last levels sent by Plugin 2 and cancel older fades. Macro 25–29 launch
touch selections; Macro 30–37 launch the eight normal cue transitions. Configuration
and audio logic remain in Plugin 2. The existing Macro 21–24 remain available.

The controller appears as **QT Py RP2040**. grandMA2's MIDI input must use it;
MIDI output and Studio One's control input use **LoopBe Internal MIDI**. The two
grandMA2 device names and IDs were verified in Windows registry preferences under
`HKCU\Software\MA Lighting Technologies\grandMA2 onPC\Settings\Midi`.
They are already stored independently of the show. Missing-device behavior at
startup has not been tested; connect the controller before launching grandMA2.

After unplugging/reconnecting the controller, refresh grandMA2's input through
the top-left yellow menu: **Options → MIDI → MIDI In Device → None**. Close and
reopen Options to refresh the device list, then choose **QT Py RP2040** again.
Keep MIDI Out on **LoopBe Internal MIDI**. This restored all five touch controls
on October 21 without restarting grandMA2 or Windows.

Build `mush_touch_v1/mush_touch_v1.ino` with `TouchFilter.h` alongside it, using
**Adafruit QT Py RP2040**, **Adafruit TinyUSB**, and **125 MHz**. Selecting XIAO
changes the sensor-bus pin defaults and did not produce touch messages in the
observed test. The filter requires 120 ms of touch, 250 ms of release to rearm,
and 500 ms of released startup settling. It cannot reject sustained false
signals solely from their duration.

The October 21 Plugin 2 update adds brief white confirmation pulses through
dedicated Executors 1.201–1.205 and Sequences 1001–1005, separate from the daily
cycle. `M.CONFIG.touch.feedback` holds note/fixture assignments and flash times;
`grandMA2/MushroomTouchFeedback.xml` contains the five white overlay cues.
The user confirmed the corrected flashes and normal sequencing on October 21.
The verified feedback mapping is:

| Note | Period | Fixture | Sequence | Executor |
|---:|---|---:|---:|---|
| 48 | First Day | 1102 | 1001 | 1.201 |
| 49 | Dusk | 1101 | 1002 | 1.202 |
| 50 | Night | 1104 | 1003 | 1.203 |
| 51 | Rainbow | 1105 | 1004 | 1.204 |
| 52 | Thunderstorm | 1103 | 1005 | 1.205 |

Feedback uses a 0.05-second attack, 0.4-second hold timer, and 0.35-second
release. It signals an accepted MIDI selection, including accidental selections
that pass the filter; rejected sensor glitches do not produce MIDI or a flash.
Natural daily transitions do not flash. The user confirmed the storm scene works,
but its sound-reactive lightning appears missing and remains under investigation.
The thunder soundtrack varies in intensity; a response during loud thunder has
not yet been verified.

On October 21 the user explicitly authorized saving Studio One and grandMA2 and
committing/pushing the checkpoint before any thunder audio editing. Both live
applications were saved, and the saved grandMA2 show was copied into the
repository with matching SHA-256. The checkpoint includes the golden song,
show, touch firmware, Plugin 2 source/import files, feedback cues, tests, and
documentation. The original thunder audio is unchanged. No startup shortcuts
or scheduled tasks were changed. See current-state sections 20–23 for
validation, saved-file hashes, and remaining limitations.

## Prepared installation startup and monitoring (not deployed)

- `StartMushroomForest.ps1`: Ordered startup; runs the existing Studio One startup
  including Transport Start, verifies the golden song, then launches grandMA2
  with `-s:mushroom_forest_current`. Plugin 2 retains MIDI and Executor 106 startup.
- `StartGrandMA2.ps1`: Starts grandMA2 only if absent and Studio One is ready.
- `StopGrandMA2.ps1`: Requests normal window close, verifies the shutdown dialog
  with Do not Save selected, then sends one Return directly to grandMA2's window.
  The underlying sequence was live-tested successfully with an unchanged show hash.
  The full guarded script still needs an approved live test before deployment.
- `Watchdog/WatchInstallation.ps1`: Logs grandMA2 process health only. Its optional
  `-RunStudioOneWatchdog` invokes the unchanged Studio One watchdog afterward.
- `InstallationControl.ps1`: Shared control, logging, and readiness functions.
- `tests/TestInstallationControl.ps1`: Isolated simulations with fake processes,
  launch/shutdown and time; test CSVs are outside Git in Windows TEMP.

Startup and shutdown scripts print a plan by default. Actual application actions
require `-Execute`; shutdown also asks for confirmation. Do not execute them
against the installation until a live test is explicitly approved.

No Startup shortcuts or scheduled tasks have been changed. The existing Studio
One recovery schedule remains active. GrandMA2 has no automatic freeze recovery
or scheduled restart. Process readiness does not prove audible playback, correct
show identity, MIDI readiness, or Executor 106 operation; these need live validation.

New runtime logs `Watchdog/InstallationLog.csv` and
`Watchdog/GrandMA2HealthLog.csv` are covered by the existing Git ignore rules.

Shutdown uses Win32 PrintWindow to capture grandMA2 independently of overlapping
desktop windows, then verifies an exact image of the prompt and selected Do not Save button,
stored in `assets/grandma2-shutdown-do-not-save.png`. This is a reviewed safety
asset, not a runtime screenshot. Calibration is for the tested 1809 x 1100 window
and display scale. A changed layout, selection, scale, or failed window capture refuses
Return and may leave the dialog open. No Save, forced termination, focus stealing,
or global keyboard input is used. Do not interact with the dialog during shutdown.

**Startup safety remains unverified:** the October 14 live test recorded a show-file
write at 19:36:21, after the `-s:mushroom_forest_current` startup and before the
shutdown attempt. Its cause is not established. Do not repeat or deploy that
startup path until it is proven not to save. The original show was preserved
outside Git; no automatic restoration is performed.
