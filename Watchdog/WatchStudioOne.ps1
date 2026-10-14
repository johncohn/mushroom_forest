$ErrorActionPreference = "Stop"

$base = "C:\Users\Mushroom Forrest\Desktop\mushroom_forest"
$logDir = Join-Path $base "Watchdog"
$logFile = Join-Path $logDir "WatchdogLog.csv"
$stateFile = Join-Path $logDir "FrozenCount.txt"
$restartScript = Join-Path $base "RestartStudioOne.ps1"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$restartMutex = New-Object System.Threading.Mutex($false, "Global\MushroomForestStudioOneRestart")
$restartBusy = $false
try {
    $restartBusy = -not $restartMutex.WaitOne(0)
    if (-not $restartBusy) { $restartMutex.ReleaseMutex() }
} finally {
    $restartMutex.Dispose()
}
if ($restartBusy) {
    Write-Host "Restart already in progress; watchdog skipping this check."
    exit 0
}

$processes = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)

if ($processes.Count -eq 0) {
    $state = "NOT_RUNNING"
}
elseif (@($processes | Where-Object { -not $_.Responding }).Count -gt 0) {
    $state = "FROZEN"
}
else {
    $state = "HEALTHY"
}

$count = 0
if (Test-Path $stateFile) {
    $saved = Get-Content $stateFile -ErrorAction SilentlyContinue
    if ($saved -match '^\d+$') {
        $count = [int]$saved
    }
}

if ($state -eq "FROZEN") {
    $count++
}
else {
    $count = 0
}

Set-Content $stateFile $count

$action = "NONE"
$reason = ""

if ($state -eq "NOT_RUNNING") {
    $action = "RESTART"
    $reason = "NOT_RUNNING"
}
elseif ($state -eq "FROZEN" -and $count -ge 2) {
    $action = "RESTART"
    $reason = "FROZEN"
}

$cooldownFile = Join-Path $logDir "LastWatchdogRestart.txt"
if ($action -eq "RESTART" -and (Test-Path $cooldownFile)) {
    $lastRestart = [datetime]::MinValue
    $savedTime = Get-Content $cooldownFile -ErrorAction SilentlyContinue
    if ([datetime]::TryParse($savedTime, [ref]$lastRestart)) {
        if (((Get-Date) - $lastRestart).TotalMinutes -lt 15) {
            $action = "COOLDOWN"
        }
    }
}

[PSCustomObject]@{
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    State = $state
    FrozenChecks = $count
    Action = $action
} | Export-Csv -Path $logFile -NoTypeInformation -Append

Write-Host "$(Get-Date -Format HH:mm:ss) Watchdog: $state; FrozenChecks=$count; Action=$action"

if ($action -eq "RESTART") {
    Set-Content $stateFile 0
    Set-Content $cooldownFile (Get-Date).ToString("o")
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $restartScript -Reason $reason
}


