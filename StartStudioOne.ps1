# Mushroom Forest - Studio One Startup and Recovery
# Run in the logged-in Windows desktop session.

$ErrorActionPreference = "Stop"

$song = "C:\Users\Mushroom Forrest\Desktop\mushroom_forest\StudioOne\Mushroom Forest Sound_Current.song"

Add-Type -AssemblyName System.Windows.Forms

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class StudioOneWindows {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(string className, string windowName);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hwnd);

    [DllImport("user32.dll")]
    public static extern void mouse_event(
        uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo
    );
}
"@

function Click-SafetyDialog {
    $hwnd = [StudioOneWindows]::FindWindow(
        "CCLDialogClass", "Studio One Safety"
    )

    if ($hwnd -eq [IntPtr]::Zero) {
        return $false
    }

    $rect = New-Object StudioOneWindows+RECT

    if (-not [StudioOneWindows]::GetWindowRect($hwnd, [ref]$rect)) {
        throw "Could not determine Safety dialog position."
    }

    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top

    Write-Host "Safety dialog detected: $width x $height"

    if ($height -lt 550 -or $height -gt 650) {
        throw "Unexpected Safety dialog height. Refusing to click."
    }

    if ($width -ge 850 -and $width -le 900) {
        # Wide crash-recovery dialog
        $radioX = 590
        $radioY = 200
        $startX = 720
        $startY = 550
    }
    elseif ($width -ge 440 -and $width -le 480) {
        # Narrow manually invoked Safety dialog
        $radioX = 165
        $radioY = 205
        $startX = 300
        $startY = 550
    }
    else {
        throw "Unknown Safety dialog layout. Refusing to click."
    }

    function Click-Relative($x, $y) {
        [void][StudioOneWindows]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 800

        [System.Windows.Forms.Cursor]::Position =
            New-Object System.Drawing.Point(
                ($rect.Left + $x),
                ($rect.Top + $y)
            )

        Start-Sleep -Milliseconds 300

        [StudioOneWindows]::mouse_event(
            2, 0, 0, 0, [UIntPtr]::Zero
        )

        [StudioOneWindows]::mouse_event(
            4, 0, 0, 0, [UIntPtr]::Zero
        )
    }

    Write-Host "Selecting Start normally..."
    Click-Relative $radioX $radioY

    Start-Sleep -Seconds 1

    Write-Host "Clicking Start..."
    Click-Relative $startX $startY

    return $true
}

# Verify the golden song exists.
if (-not (Test-Path -LiteralPath $song)) {
    throw "Song file not found: $song"
}

# Launch Studio One if necessary.
$process = Get-Process "Studio One" -ErrorAction SilentlyContinue

if (-not $process) {
    Write-Host "$(Get-Date -Format HH:mm:ss) Launching Mushroom Forest song..."
    Start-Process -FilePath $song
}
else {
    Write-Host "$(Get-Date -Format HH:mm:ss) Studio One process already exists."
}

# Watch for Safety dialog and allow Studio One to initialize.
$safetyHandled = $false
$deadline = (Get-Date).AddSeconds(90)

while ((Get-Date) -lt $deadline) {
    $safety = [StudioOneWindows]::FindWindow(
        "CCLDialogClass", "Studio One Safety"
    )

    if ($safety -ne [IntPtr]::Zero) {
        if ($safetyHandled) {
            throw "Safety dialog remained open after recovery attempt."
        }

        $safetyHandled = Click-SafetyDialog
        Write-Host "$(Get-Date -Format HH:mm:ss) Studio One ready; waiting 5 seconds..."; Start-Sleep -Seconds 5
    }

    $process = Get-Process "Studio One" -ErrorAction SilentlyContinue

    if ($process -and
        $process.Responding -and
        ($process.MainWindowTitle -like "Studio One*") -and
        ($safety -eq [IntPtr]::Zero)) {

        # Allow time for the song and audio device to finish loading.
        Write-Host "$(Get-Date -Format HH:mm:ss) Studio One ready; waiting 5 seconds..."; Start-Sleep -Seconds 5

        # Check that Safety dialog has not reappeared.
        $safety = [StudioOneWindows]::FindWindow(
            "CCLDialogClass", "Studio One Safety"
        )

        if ($safety -eq [IntPtr]::Zero) {
            break
        }
    }

    Start-Sleep -Seconds 2
}

if ([StudioOneWindows]::FindWindow(
    "CCLDialogClass", "Studio One Safety"
) -ne [IntPtr]::Zero) {
    throw "Studio One Safety dialog is still open."
}

$process = Get-Process "Studio One" -ErrorAction SilentlyContinue

if (-not $process -or -not $process.Responding) {
    throw "Studio One is not responding."
}

# Send the dedicated Transport Start shortcut.
$wshell = New-Object -ComObject WScript.Shell

if (-not $wshell.AppActivate("Studio One")) {
    throw "Could not activate Studio One."
}

Start-Sleep -Seconds 2

$wshell.SendKeys("^%{F9}")

Write-Host "$(Get-Date -Format HH:mm:ss) Studio One startup completed. Playback command sent."












