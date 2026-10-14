param([string]$Reason = "SCHEDULED")
$ErrorActionPreference = "Stop"
$mutex = New-Object System.Threading.Mutex($false, "Global\MushroomForestStudioOneRestart")
$locked = $false
try {
    $locked = $mutex.WaitOne(0)
    if (-not $locked) {
        Write-Host "Another Studio One restart is already running."
        exit
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class StudioRestartWin {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
    }
}
"@

    . "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\Watchdog\RestartLogging.ps1"
    $restartStart = Get-Date
    $initialProcesses = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
    $initialState = if ($initialProcesses.Count -eq 0) { "NOT_RUNNING" } elseif (@($initialProcesses | Where-Object { -not $_.Responding }).Count -gt 0) { "FROZEN" } else { "RESPONSIVE" }
    $shutdownMethod = if ($initialState -eq "NOT_RUNNING") { "ALREADY_STOPPED" } else { "GRACEFUL" }
    Write-Host "$(Get-Date -Format HH:mm:ss) Restarting Studio One. Reason=$Reason InitialState=$initialState"
    $processes = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)

    foreach ($proc in $processes) {
        if ($proc.Responding) {
            [void]$proc.CloseMainWindow()
        }
    }

    $deadline = (Get-Date).AddSeconds(15)

    while ((Get-Date) -lt $deadline) {
        $running = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
        if ($running.Count -eq 0) { break }

        $h = [StudioRestartWin]::FindWindow("#32770", "Studio One")

        if ($h -ne [IntPtr]::Zero) {
            $r = New-Object StudioRestartWin+RECT
            [void][StudioRestartWin]::GetWindowRect($h, [ref]$r)
            $w = $r.Right - $r.Left
            $height = $r.Bottom - $r.Top

            if ($w -ge 430 -and $w -le 500 -and $height -ge 110 -and $height -le 155) {
                Write-Host "Selecting No on save dialog..."
                [void][StudioRestartWin]::SetForegroundWindow($h)
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($r.Left + [int]($w * 0.73)), ($r.Top + [int]($height * 0.80)))
                [StudioRestartWin]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
                [StudioRestartWin]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
            }
        }

        Start-Sleep -Seconds 1
    }

    $remaining = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
    if ($remaining.Count -gt 0) {
        $shutdownMethod = "FORCED"
        Write-Host "Studio One did not close normally; forcing termination..."
        $remaining | Stop-Process -Force
        Start-Sleep -Seconds 3
    }

    $startup = "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\StartStudioOne.ps1"
    Write-Host "Starting Studio One..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startup
    Start-Sleep -Seconds 2
    $recovered = @(Get-Process "Studio One" -ErrorAction SilentlyContinue | Where-Object { $_.Responding -and $_.MainWindowTitle -like "*Mushroom Forest Sound_Current*" })
    $result = if ($recovered.Count -gt 0 -and $LASTEXITCODE -eq 0) { "SUCCESS" } else { "FAILED" }
    $restartEnd = Get-Date
    $duration = [math]::Round(($restartEnd - $restartStart).TotalSeconds, 1)
    Write-RestartLog -StartTime $restartStart.ToString("yyyy-MM-dd HH:mm:ss") -Reason $Reason -InitialState $initialState -ShutdownMethod $shutdownMethod -Result $result -DurationSeconds $duration -EndTime $restartEnd.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "Restart result: $result; Reason: $Reason; Initial state: $initialState; Shutdown: $shutdownMethod; Duration: $duration seconds"
    if ($result -ne "SUCCESS") { throw "Studio One recovery verification failed." }
}
catch { Write-Host "RESTART ERROR: $(param([string]$Reason = "SCHEDULED")
$ErrorActionPreference = "Stop"
$mutex = New-Object System.Threading.Mutex($false, "Global\MushroomForestStudioOneRestart")
$locked = $false
try {
    $locked = $mutex.WaitOne(0)
    if (-not $locked) {
        Write-Host "Another Studio One restart is already running."
        exit
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class StudioRestartWin {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
    }
}
"@

    . "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\Watchdog\RestartLogging.ps1"
    $restartStart = Get-Date
    $initialProcesses = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
    $initialState = if ($initialProcesses.Count -eq 0) { "NOT_RUNNING" } elseif (@($initialProcesses | Where-Object { -not $_.Responding }).Count -gt 0) { "FROZEN" } else { "RESPONSIVE" }
    $shutdownMethod = if ($initialState -eq "NOT_RUNNING") { "ALREADY_STOPPED" } else { "GRACEFUL" }
    Write-Host "$(Get-Date -Format HH:mm:ss) Restarting Studio One. Reason=$Reason InitialState=$initialState"
    $processes = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)

    foreach ($proc in $processes) {
        if ($proc.Responding) {
            [void]$proc.CloseMainWindow()
        }
    }

    $deadline = (Get-Date).AddSeconds(15)

    while ((Get-Date) -lt $deadline) {
        $running = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
        if ($running.Count -eq 0) { break }

        $h = [StudioRestartWin]::FindWindow("#32770", "Studio One")

        if ($h -ne [IntPtr]::Zero) {
            $r = New-Object StudioRestartWin+RECT
            [void][StudioRestartWin]::GetWindowRect($h, [ref]$r)
            $w = $r.Right - $r.Left
            $height = $r.Bottom - $r.Top

            if ($w -ge 430 -and $w -le 500 -and $height -ge 110 -and $height -le 155) {
                Write-Host "Selecting No on save dialog..."
                [void][StudioRestartWin]::SetForegroundWindow($h)
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($r.Left + [int]($w * 0.73)), ($r.Top + [int]($height * 0.80)))
                [StudioRestartWin]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
                [StudioRestartWin]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
            }
        }

        Start-Sleep -Seconds 1
    }

    $remaining = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
    if ($remaining.Count -gt 0) {
        $shutdownMethod = "FORCED"
        Write-Host "Studio One did not close normally; forcing termination..."
        $remaining | Stop-Process -Force
        Start-Sleep -Seconds 3
    }

    $startup = "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\StartStudioOne.ps1"
    Write-Host "Starting Studio One..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startup
    Start-Sleep -Seconds 2
    $recovered = @(Get-Process "Studio One" -ErrorAction SilentlyContinue | Where-Object { $_.Responding -and $_.MainWindowTitle -like "*Mushroom Forest Sound_Current*" })
    $result = if ($recovered.Count -gt 0 -and $LASTEXITCODE -eq 0) { "SUCCESS" } else { "FAILED" }
    $restartEnd = Get-Date
    $duration = [math]::Round(($restartEnd - $restartStart).TotalSeconds, 1)
    Write-RestartLog -StartTime $restartStart.ToString("yyyy-MM-dd HH:mm:ss") -Reason $Reason -InitialState $initialState -ShutdownMethod $shutdownMethod -Result $result -DurationSeconds $duration -EndTime $restartEnd.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "Restart result: $result; Reason: $Reason; Initial state: $initialState; Shutdown: $shutdownMethod; Duration: $duration seconds"
    if ($result -ne "SUCCESS") { throw "Studio One recovery verification failed." }
}
finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}





.Exception.Message)" -ForegroundColor Red; if($restartStart -and $result -ne "FAILED"){ $end=Get-Date; $duration=[math]::Round(($end-$restartStart).TotalSeconds,1); try { Write-RestartLog -StartTime $restartStart.ToString("yyyy-MM-dd HH:mm:ss") -Reason $Reason -InitialState $initialState -ShutdownMethod $shutdownMethod -Result "FAILED" -DurationSeconds $duration -EndTime $end.ToString("yyyy-MM-dd HH:mm:ss") } catch { Write-Host "Logging failed: $(param([string]$Reason = "SCHEDULED")
$ErrorActionPreference = "Stop"
$mutex = New-Object System.Threading.Mutex($false, "Global\MushroomForestStudioOneRestart")
$locked = $false
try {
    $locked = $mutex.WaitOne(0)
    if (-not $locked) {
        Write-Host "Another Studio One restart is already running."
        exit
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class StudioRestartWin {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
    }
}
"@

    . "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\Watchdog\RestartLogging.ps1"
    $restartStart = Get-Date
    $initialProcesses = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
    $initialState = if ($initialProcesses.Count -eq 0) { "NOT_RUNNING" } elseif (@($initialProcesses | Where-Object { -not $_.Responding }).Count -gt 0) { "FROZEN" } else { "RESPONSIVE" }
    $shutdownMethod = if ($initialState -eq "NOT_RUNNING") { "ALREADY_STOPPED" } else { "GRACEFUL" }
    Write-Host "$(Get-Date -Format HH:mm:ss) Restarting Studio One. Reason=$Reason InitialState=$initialState"
    $processes = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)

    foreach ($proc in $processes) {
        if ($proc.Responding) {
            [void]$proc.CloseMainWindow()
        }
    }

    $deadline = (Get-Date).AddSeconds(15)

    while ((Get-Date) -lt $deadline) {
        $running = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
        if ($running.Count -eq 0) { break }

        $h = [StudioRestartWin]::FindWindow("#32770", "Studio One")

        if ($h -ne [IntPtr]::Zero) {
            $r = New-Object StudioRestartWin+RECT
            [void][StudioRestartWin]::GetWindowRect($h, [ref]$r)
            $w = $r.Right - $r.Left
            $height = $r.Bottom - $r.Top

            if ($w -ge 430 -and $w -le 500 -and $height -ge 110 -and $height -le 155) {
                Write-Host "Selecting No on save dialog..."
                [void][StudioRestartWin]::SetForegroundWindow($h)
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($r.Left + [int]($w * 0.73)), ($r.Top + [int]($height * 0.80)))
                [StudioRestartWin]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
                [StudioRestartWin]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
            }
        }

        Start-Sleep -Seconds 1
    }

    $remaining = @(Get-Process "Studio One" -ErrorAction SilentlyContinue)
    if ($remaining.Count -gt 0) {
        $shutdownMethod = "FORCED"
        Write-Host "Studio One did not close normally; forcing termination..."
        $remaining | Stop-Process -Force
        Start-Sleep -Seconds 3
    }

    $startup = "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\StartStudioOne.ps1"
    Write-Host "Starting Studio One..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startup
    Start-Sleep -Seconds 2
    $recovered = @(Get-Process "Studio One" -ErrorAction SilentlyContinue | Where-Object { $_.Responding -and $_.MainWindowTitle -like "*Mushroom Forest Sound_Current*" })
    $result = if ($recovered.Count -gt 0 -and $LASTEXITCODE -eq 0) { "SUCCESS" } else { "FAILED" }
    $restartEnd = Get-Date
    $duration = [math]::Round(($restartEnd - $restartStart).TotalSeconds, 1)
    Write-RestartLog -StartTime $restartStart.ToString("yyyy-MM-dd HH:mm:ss") -Reason $Reason -InitialState $initialState -ShutdownMethod $shutdownMethod -Result $result -DurationSeconds $duration -EndTime $restartEnd.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "Restart result: $result; Reason: $Reason; Initial state: $initialState; Shutdown: $shutdownMethod; Duration: $duration seconds"
    if ($result -ne "SUCCESS") { throw "Studio One recovery verification failed." }
}
finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}





.Exception.Message)" } }; throw }
finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}






