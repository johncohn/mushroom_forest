function Write-RestartLog {
    param(
        [string]$StartTime,
        [string]$Reason,
        [string]$InitialState,
        [string]$ShutdownMethod,
        [string]$Result,
        [double]$DurationSeconds,
        [string]$EndTime
    )

    $logDir = "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\Watchdog"
    $logFile = Join-Path $logDir "RestartLog.csv"

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    [PSCustomObject]@{
        StartTime       = $StartTime
        Reason          = $Reason
        InitialState    = $InitialState
        ShutdownMethod  = $ShutdownMethod
        Result          = $Result
        DurationSeconds = $DurationSeconds
        EndTime         = $EndTime
    } | Export-Csv -Path $logFile -NoTypeInformation -Append
}
