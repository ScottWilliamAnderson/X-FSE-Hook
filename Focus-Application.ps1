# Focus-Application.ps1
# Wrapper script to launch an application and bring it to the foreground
# This addresses the issue where hooked applications start in the background

param(
    [Parameter(Mandatory=$true)]
    [string]$ApplicationPath
)

# Define Win32 API functions for window management
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern bool IsIconic(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern bool AllowSetForegroundWindow(int dwProcessId);
        
        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
        public const int SW_SHOWNORMAL = 1;
    }
"@

function Set-WindowFocus {
    param(
        [System.Diagnostics.Process]$Process,
        [int]$MaxRetries = 10,
        [int]$RetryDelayMs = 500
    )
    
    $retryCount = 0
    $success = $false
    
    while ($retryCount -lt $MaxRetries -and -not $success) {
        try {
            # Refresh the process to get updated MainWindowHandle
            $Process.Refresh()
            
            # Wait for the process to have a main window
            if ($Process.MainWindowHandle -eq [IntPtr]::Zero) {
                Start-Sleep -Milliseconds $RetryDelayMs
                $retryCount++
                continue
            }
            
            # Get the main window handle
            $hwnd = $Process.MainWindowHandle
            
            # Allow this script to set foreground window
            [WindowHelper]::AllowSetForegroundWindow($Process.Id)
            
            # If the window is minimized, restore it first
            if ([WindowHelper]::IsIconic($hwnd)) {
                [WindowHelper]::ShowWindow($hwnd, [WindowHelper]::SW_RESTORE) | Out-Null
                Start-Sleep -Milliseconds 100
            }
            
            # Show the window
            [WindowHelper]::ShowWindow($hwnd, [WindowHelper]::SW_SHOW) | Out-Null
            Start-Sleep -Milliseconds 100
            
            # Set it to foreground
            $result = [WindowHelper]::SetForegroundWindow($hwnd)
            
            if ($result) {
                Write-Host "Successfully brought window to foreground: $($Process.ProcessName) (PID: $($Process.Id))"
                $success = $true
            } else {
                Write-Host "Attempt $($retryCount + 1): Failed to set foreground, retrying..."
                Start-Sleep -Milliseconds $RetryDelayMs
                $retryCount++
            }
        }
        catch {
            Write-Host "Error on attempt $($retryCount + 1): $_"
            Start-Sleep -Milliseconds $RetryDelayMs
            $retryCount++
        }
    }
    
    return $success
}

# Main execution
try {
    # Check if the application path exists
    if (-not (Test-Path $ApplicationPath)) {
        Write-Error "Application not found: $ApplicationPath"
        exit 1
    }
    
    Write-Host "Launching application: $ApplicationPath"
    
    # Start the process
    $process = Start-Process -FilePath $ApplicationPath -PassThru
    
    if ($null -eq $process) {
        Write-Error "Failed to start process"
        exit 1
    }
    
    Write-Host "Process started with PID: $($process.Id)"
    
    # Wait a moment for the application to initialize
    Start-Sleep -Milliseconds 1000
    
    # Attempt to bring the window to focus
    $focusResult = Set-WindowFocus -Process $process -MaxRetries 20 -RetryDelayMs 500
    
    if (-not $focusResult) {
        Write-Warning "Could not bring window to foreground after multiple attempts. Window may still be starting."
    }
    
    exit 0
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
