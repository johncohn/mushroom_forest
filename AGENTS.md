# Instructions for Codex sessions

## Start here

- Read `README.md` and `docs/mushroom_forest_current_state.md` before working on the installation. The September checkpoint document includes later recovery work, October 20–21 touch updates in sections 20–22, and the authorized saved checkpoint in section 23.
- Treat this as a working lighting and audio installation. Limit changes to the user's authorized scope.
- Documentation describes the intended setup; verify relevant details with read-only checks before relying on them for changes.

## Safety and permission

- Never save or overwrite the golden Studio One song during automatic recovery: `StudioOne/Mushroom Forest Sound_Current.song`. Recovery must discard unsaved changes, decline save prompts, and reopen the golden song without overwriting it with crash-recovery content. Never add automatic saving to recovery scripts.
- Never modify the live grandMA2 show without explicit permission. Its live path is `C:\ProgramData\MA Lighting Technologies\grandma\gma2_V_3.9.60\shows\mushroom_forest_current.show.gz`. The repository copy at `grandMA2/mushroom_forest_current.show.gz` is a checkpoint, not the live show.
- Never restart, terminate, interrupt, or stop playback in Studio One or grandMA2 without asking first. This includes running startup, restart, watchdog, reset, or show-control commands that affect the running installation, and rebooting Windows.
- Do not create, modify, disable, enable, delete, or manually trigger scheduled tasks without permission. Existing tasks are `MushroomForest_StudioOne_Restart` and `MushroomForest_StudioOne_Watchdog`.
- Existing scheduled recovery does not authorize Codex to initiate a restart or alter its schedule.
- Do not commit or push changes without asking. Documentation checkpoint steps are reference procedures, not standing authorization to save live applications, commit, or push.

## Changes and verification

- Preserve working scripts before significant changes using a backup outside Git or a verified ignored location. Do not overwrite the only working copy.
- Keep logs, temporary files, runtime state, and backups out of Git. Verify ignore coverage before creating these artifacts in the repository; do not stage them. Studio One `Cache` and `History` also remain excluded.
- Test changes before deploying them. Prefer static checks, isolated fixtures, and dry runs that do not affect the installation. Obtain permission before any test that restarts applications, changes the live show, affects playback, or changes scheduled tasks.
- Report what changed, what was tested, and any remaining limitations. Do not describe untested live behavior as verified.

## Architecture and configuration

- grandMA2 onPC v3.9.60 is the master show/state controller. Studio One 5 plays environmental audio; LoopBe Internal MIDI carries grandMA2 control messages.
- Executor 106 runs Sequence 2 for the daily cycle: Day, Thunderstorm, Rainbow, Rainbow Off, New Day, Dusk, Night, and Dawn.
- Plugin 2, Mushroom Control, is the central configuration and audio-control location. Macros 21-24 are small transition launchers; do not introduce hard-coded levels or times into them.
- Edit sound levels in `M.CONFIG.audio`, state durations in `M.CONFIG.timing`, audio crossfades in `M.CONFIG.fade`, and startup delay in `M.CONFIG.startup.waitForStudioOne`, subject to live-show permission.
- Documented MIDI assignments: CC49 Water (45), CC50 Night (50), CC51 Day (50), CC52 Thunderstorm (30), and CC53 Transport Start (127 press/release pulse). Zero silences CC49-52.
- Keep the duplicate hidden `night-forest` track muted and preserve existing AC sends and working audio routing.
- Current cue durations are temporary 40-second development values. Do not assume these are final production timings.
- Plugin 2 has Execute On Load enabled and can start audio and Executor 106. Treat loading it as an action that can affect the live installation.

## Recovery context

- `StartStudioOne.ps1` opens the golden song and starts playback. `RestartStudioOne.ps1` restarts Studio One without saving. `Watchdog/WatchStudioOne.ps1` detects failures; `Watchdog/RestartLogging.ps1` records restart results.
- Scheduled Studio One restarts occur daily at 6:00 AM and 6:00 PM. The watchdog checks every five minutes, recovers after two consecutive unresponsive checks or immediately when the process is absent, and uses a 15-minute cooldown and a mutex to prevent repeated or overlapping recovery.
- Recovery checks process responsiveness and the loaded song. Since October 15, `StartStudioOne.ps1` also uses `StudioOnePlayback.ps1` to verify recognized Play state and transport movement before returning success. Audible output is not independently verified. GUI automation requires an interactive Windows session.
- grandMA2 is not included in scheduled restarts. Unattended freeze recovery and full Windows reboot recovery still require testing; those tests need permission before disrupting the installation.
- Runtime artifacts include `Watchdog/RestartLog.csv`, `Watchdog/WatchdogLog.csv`, `Watchdog/FrozenCount.txt`, and `Watchdog/LastWatchdogRestart.txt`. Keep them out of Git.

## Prepared installation control (not deployed)

- `StartMushroomForest.ps1`, `StartGrandMA2.ps1`, and `StopGrandMA2.ps1` default to plan-only output. Do not use `-Execute` without authorization to affect the applications.
- Keep Studio One's dedicated Transport Start on every startup/recovery. Plugin 2 keeps its separate CC53 Start and all audio/Executor 106 initialization; do not replace or duplicate its orchestration in PowerShell.
- Ordered startup requests the live show via `-s:mushroom_forest_current` and leaves an existing grandMA2 instance alone. Process/window readiness does not verify the loaded show or Plugin 2 execution.
- Supported no-save grandMA2 shutdown methods are the previously tested `Shutdown /nosave /noconfirm` inside grandMA2, or the October 14 live-tested local method: normal `CloseMainWindow()`, verify Do not Save is selected, then post one Return directly to the owned window. The local method closed gracefully with an unchanged live-show hash; the full guarded script is not yet live-tested or deployed.
- `StopGrandMA2.ps1` uses the local dialog method with process/window verification and an exact selected-button image check. Win32 PrintWindow captures the owned grandMA2 window independently of overlapping desktop windows. Keep the reviewed `assets/grandma2-shutdown-do-not-save.png` safety asset in Git. Current calibration is for a 1809 x 1100 window and the tested display scale. Changed UI or failed capture must refuse Return; never assume the default selection, use global SendKeys, or force termination. Do not alter calibration without inspecting a known-safe dialog.
- The October 14 live startup with `-s:mushroom_forest_current` was followed by a show-file write at 19:36:21, before shutdown was attempted. The cause is unresolved. Never repeat or deploy that startup path until no-save behavior is established. No-save applies to startup as well as shutdown/recovery, even for runtime metadata; never restore or overwrite the show automatically.
- `Watchdog/WatchInstallation.ps1` is a prepared entry point, not the currently scheduled script. Its grandMA2 monitoring is strictly log-only. Do not add automatic grandMA2 recovery or daily restarts.
- `Watchdog/InstallationLog.csv` and `Watchdog/GrandMA2HealthLog.csv` are ignored runtime logs. Isolated tests in `tests/TestInstallationControl.ps1` use Windows TEMP for artifacts.
- Startup shortcuts and scheduled tasks remain unchanged. Live testing and deployment need explicit authorization.

## Water lighting (October 19, 2026)

- October 19 water-lighting work is documented in current-state section 19. The user approved adding the existing Effect 1 (Water), for Group 1 fixtures 101-250 only, to Sequence 2 Cues 1, 1.3, and 1.4. Exact XML comparison verified 1,800 effect-only additions and no other sequence changes. The user subsequently explicitly authorized one live-show save at about 19:30, without committing until in-person verification. The saved live-show SHA-256 is B4E82CB28B065F5F094B3F5587DBE9BE8250126734B5DDEF3AF069437BADE720; the repository checkpoint remains unchanged. Backups are outside Git in Documents/MushroomForestBackups/20261019-193013-water-fix. This one-time permission does not authorize automatic recovery saves or future commits. Verify current state before relying on this note.
- The approved natural-cycle DMX test completed with 360 samples across all eight phases: all 150 Water fixtures remained nonzero and animated, including after Rainbow and during Day, Thunderstorm, and Night. On October 20 the user confirmed the physical water feature looks good. No application restart was performed during that correction. Explicit commit permission is still required before committing the new show.

## Mushroom touch periods (October 20, 2026)

- The user authorized changing sensor selections to enter the matching Sequence 2 period with matching sound, then continue normal timed progression. Day always means the first Day, Cue 1. These changes were subsequently saved in the explicitly authorized October 21 checkpoint (section 23). No restart/reload persistence test has been performed; future show saves need separate permission.
- Read `grandMA2/MushroomControl.lua` and current-state section 20 before changing this behavior. Plugin 2 remains the central configuration/control location. `M.CONFIG.touch` holds the fade (two seconds), debounce, daily executor, and five-note mapping; `M.CONFIG.periods` holds the cue/audio/auxiliary-lighting map. Macro 25–29 launch touch selections, and Macro 30–37 launch the eight daily cue callbacks. Existing Macro 21–24 remain unchanged. Do not put levels or durations in these launchers.
- Observed notes are 48 Day, 49 Dusk (formerly Dark Mode), 50 Night/Evening, 51 Rainbow, and 52 Thunderstorm. No separate Dawn sensor was observed. The proposed Dusk mapping was offered for optional clarification; honor any later user correction.
- Audio fades must start from the last CC values actually sent, include all four environmental tracks, and cancel superseded writes. A delayed period callback must refuse to act when that cue is no longer active. Preserve the separate startup CC53 pulse and `started` guard; source hot updates must not invoke startup/reset.
- grandMA2's input is QT Py RP2040 and output is LoopBe Internal MIDI. Read-only inspection verified both names and IDs in `HKCU\Software\MA Lighting Technologies\grandMA2 onPC\Settings\Midi`; those preferences are already persisted independently of the show. Do not edit numeric indices blindly. Restart/missing-device behavior has not been tested.
- Additional sensor notes were observed overriding test selections. Controlled live tests temporarily filter note dispatch, with bounded expiry and explicit restoration; never leave a test filter installed. Use separate short selection and observation commands for live tests, because a long-running parent Lua test can delay its cue macros. Validation details and remaining physical checks belong in current-state section 20.
- The October 20 v2 checks passed 80 isolated scenarios and 340 live timer samples, with 70 incoming selections temporarily filtered. They did not verify untouched, input-enabled operation. October 21 re-export verified the stored v2 source before the subsequent v3 update. No show save or commit was issued.

## Mushroom filtering and feedback (October 21, 2026)

- Plugin 2 source is `2026-10-21-touch-v3`. The user confirmed the corrected physical flashes and that sequencing appears correct. The live touch changes were subsequently saved in the authorized checkpoint below. The storm scene works, but its sound-reactive lightning appears missing; do not describe that response as fixed. The soundtrack varies in thunder intensity, and a response during loud thunder has not yet been verified.
- Raw USB MIDI and passive Lua traces linked unwanted rapid cue jumps to incoming notes while the user reported no touches; all 29 traced cue callbacks followed matching selections. Configuration and stored cue timers remained 40 seconds. Do not attribute this observed pattern to corrupted timing data without new evidence.
- `mush_touch_v1/TouchFilter.h` requires 120 ms touched, 250 ms released to rearm, and 500 ms released at startup. Each sensor is independent; held-at-startup sensors must release before arming. Fixed 10-ms Note Off pulses are not measurements of touch duration. Sustained interference can still pass.
- The user uploaded the corrected firmware through Arduino IDE. Build as Adafruit QT Py RP2040, Adafruit TinyUSB, 125 MHz. The earlier XIAO build used different sensor-bus defaults and did not produce touch messages. Six compile-time filter scenarios and a complete RP2040 build passed; do not repeat upload/reset actions without authorization.
- A verified reconnect procedure avoids restarting: Options → MIDI → MIDI In Device → None; close and reopen Options to refresh the list; select QT Py RP2040. Preserve MIDI Out as LoopBe Internal MIDI. All five notes then reached grandMA2. Cold-boot behavior remains untested.
- `M.CONFIG.touch.feedback` and `grandMA2/MushroomTouchFeedback.xml` define white overlays: note 48/Day → fixture 1102, Sequence 1001, Executor 1.201; 49/Dusk → 1101/1002/1.202; 50/Night → 1104/1003/1.203; 51/Rainbow → 1105/1004/1.204; 52/Thunderstorm → 1103/1005/1.205. Do not assume fixture order equals note order.
- Feedback executors use Super priority, with 0.05-second attack, 0.4-second hold timer, and 0.35-second release. Flash after scene-overlay activation; guard resource ownership and stale release timers. Natural cue progression does not flash. A same-period request suppressed by Lua debounce still flashes; a firmware-rejected glitch emits no MIDI and cannot flash.
- The v3 update preserves compatible in-flight audio fades on definition-only reload. New transitions cancel older generations; preserve rejection of old writes without a generation token. All 86 isolated Lua scenarios passed after the final physical remapping. Daily Sequence 2 was unchanged during feedback installation. Evidence and backups are in Windows TEMP, outside Git.
- No application restart, playback stop, show/song save, scheduled-task change, commit, or push was performed for the October 21 correction. Keep the duplicate hidden night track muted and existing audio routing intact while investigating missing thunderstorm lightning.

## Authorized manual checkpoint (October 21, 2026)

- After the correction, the user explicitly requested saving Studio One, grandMA2, touch code, and documentation and committing/pushing them before further thunder editing. This supersedes the earlier unsaved notes. Studio One was saved at about 16:02 and grandMA2 through its owned Backup → Save Show control at 16:06:12; no restart or playback stop was issued. This one-time manual authorization does not authorize future saves or recovery saving.
- Saved live show and repository show SHA-256: `C3DBE69F6C1CD8A17748A7F62D92289F3E533D460B46F5CC3FF231705F1C3AA5`. Golden song SHA-256: `70DD144B577700CB8001E042BA0ED19E31BD5963FA0DB96526A8E2F3B5F16B79`. Backups and save verification are outside Git in TEMP/MushroomForest-checkpoint-20261021-155306. See current-state section 23.
- The user wants the strongest real thunder passage selected from existing audio and moved/trimmed into the looping portion, rather than synthesized claps. That audio edit is pending until after this checkpoint. Existing thunder WAV files are identical by SHA-256 and were not edited. The on-disk pre-save song had a 0–300-second loop; recheck the newly saved song/live layout before editing.

## Studio One playback control

- Do not reintroduce foreground-dependent AppActivate/SendKeys for Transport Start. AppActivate returned True during live tests while Windows Terminal remained foreground.
- `StudioOnePlayback.ps1` targets the verified Play control in Studio One's owned window, using PrintWindow and reviewed `assets/studioone-play-*.png` states. Keep these safety assets with the helper in Git. Never click an unrecognized control or unknown layout.
- Current transport calibration is a 1936 x 1048 window at the tested scale. Startup resolves the actual golden-song window and requests maximization to the reviewed layout if minimized or resized before inspecting Play. Failed restoration, other sizes or unknown appearances fail explicitly. Moving or covering the window is supported. Recalibration requires inspecting the actual control. The October 16 approved live test restored a minimized window, sent one Start, verified movement, and verified already-playing state without another click. Both application PIDs and song/show hashes were unchanged. A full scheduled restart with this correction remains unverified.
- Playback success requires recognized playing state and an advancing time display across three samples. Keep bounded Start retries and failure propagation to restart logs. Never toggle already-playing transport or use save commands as part of playback control.
- `Watchdog/PlaybackLog.csv` is an ignored runtime log. Regular watchdog checks still monitor process health only; playback verification runs during startup/recovery.
