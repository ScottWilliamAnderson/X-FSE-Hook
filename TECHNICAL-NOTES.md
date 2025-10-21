# Technical Notes: Window Focus Implementation

## Problem Statement

When X-FSE Hook launches applications via the Windows `Userinit` registry key at sign-in, the applications start in the background while Xbox Full-Screen Experience (X-FSE) stays in focus. This is particularly noticeable with Playnite Fullscreen, which users expect to see immediately after login.

## Solution Overview

The solution involves a two-part approach:

1. **Wrapper Script** (`Focus-Application.ps1`): A PowerShell script that launches the target application and brings its window to the foreground using Win32 APIs.

2. **Integration** (`XFSE-Hook.Export.ps1`): Modified the main tool to use the wrapper script instead of launching applications directly.

## Implementation Details

### Focus-Application.ps1

The wrapper script:
- Uses P/Invoke to call Win32 API functions:
  - `SetForegroundWindow` - Brings a window to the foreground
  - `ShowWindow` - Shows or restores a window
  - `IsIconic` - Checks if a window is minimized
  - `AllowSetForegroundWindow` - Grants permission to set foreground window
  
- Implements retry logic (up to 20 attempts) to handle cases where the application window isn't immediately available
- Waits for the process to initialize and create its main window
- Handles minimized windows by restoring them before setting focus

### XFSE-Hook.Export.ps1 Modifications

Added `Set-HookWithFocus` helper function that:
- Locates the `Focus-Application.ps1` wrapper script
- Constructs a registry value that launches PowerShell with the wrapper
- Passes the target application path as a parameter

Modified all hook functions to use the helper:
- `$buttonHookSelection_Click` - Hook selected applications from list
- `$buttonHookProgramManually_Click` - Hook manually selected executable
- `$buttonHookSteam_Click` - Hook Steam preset
- `$buttonHookPlayniteFS_Click` - Hook Playnite Fullscreen preset  
- `$buttonHookGOG_Click` - Hook GOG Galaxy preset

### Registry Value Format

**Before:**
```
C:\Windows\System32\userinit.exe,C:\Path\To\Application.exe,
```

**After:**
```
C:\Windows\System32\userinit.exe,powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\Focus-Application.ps1" -ApplicationPath "C:\Path\To\Application.exe",
```

## Benefits

1. **Automatic Focus**: Hooked applications automatically come to the foreground
2. **Robust**: Retry logic handles slow-starting applications
3. **Non-Invasive**: Doesn't modify the target applications themselves
4. **Reversible**: Can easily revert to default Windows behavior

## Limitations

- PowerShell execution policy must allow running scripts (handled via `-ExecutionPolicy Bypass`)
- Both `XFSE-Hook.Export.ps1` and `Focus-Application.ps1` must be in the same directory
- Requires the application to create a window with a main window handle

## Testing Considerations

Manual testing required on Windows with:
1. Install X-FSE Hook and hook an application (e.g., Playnite Fullscreen)
2. Sign out and sign back in
3. Verify the hooked application appears in the foreground
4. Verify Xbox FSE is not blocking the hooked application

## Future Enhancements

Potential improvements:
- Add configurable retry count and delay
- Support for applications without main window handles
- Logging for troubleshooting window focus issues
- Option to disable focus behavior for specific applications
