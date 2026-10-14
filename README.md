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

## Important
Automatic restarts must NEVER save changes to the golden Studio One song.
Logs, temporary state files, and backup scripts are excluded from Git.
grandMA2 is not yet included in scheduled restarts.
