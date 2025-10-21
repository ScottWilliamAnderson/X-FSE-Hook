# Quick Start: Window Focus Feature

## What's New?

X-FSE Hook now automatically brings hooked applications to the foreground when they start! This solves the issue where apps like Playnite Fullscreen would start in the background while Xbox FSE stayed in focus.

## How It Works

When you hook an application, X-FSE Hook now:
1. Creates a wrapper that launches your application
2. Waits for the application window to appear
3. Automatically brings it to the foreground using Windows APIs

**No additional configuration needed!** Just hook your application as usual.

## Installation/Setup

1. Ensure both files are in the same directory:
   - `XFSE-Hook.Export.ps1` (the main tool)
   - `Focus-Application.ps1` (the wrapper script)

2. Run X-FSE Hook as Administrator (required for registry changes)

3. Hook your desired application using any method:
   - Select from scanned apps and click "Hook Selection"
   - Use a preset button (Playnite FS, Steam, GOG)
   - Manually select an executable

That's it! Your hooked application will now automatically come to the foreground on startup.

## Verification

To verify the feature is working:

1. Hook an application (e.g., Playnite Fullscreen)
2. Sign out of Windows
3. Sign back in
4. The hooked application should appear in the foreground

## Troubleshooting

### Application doesn't come to foreground

**Check 1: File Location**
- Ensure `Focus-Application.ps1` is in the same directory as `XFSE-Hook.Export.ps1`

**Check 2: PowerShell Execution Policy**
- The wrapper uses `-ExecutionPolicy Bypass`, so this shouldn't be an issue
- If you see errors, try: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Check 3: Registry Value**
- Open Registry Editor (regedit.exe)
- Navigate to: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`
- Check the `Userinit` value - it should contain:
  ```
  C:\Windows\System32\userinit.exe,powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\Focus-Application.ps1" -ApplicationPath "C:\Path\To\YourApp.exe",
  ```

**Check 4: Application Type**
- The wrapper works with standard Windows applications that create a main window
- Some UWP apps may behave differently

### Still Having Issues?

Run the test script to verify the installation:
```powershell
.\Test-FocusWrapper.ps1
```

If all tests pass but the application still doesn't come to foreground, there may be a timing issue with your specific application. The wrapper retries for up to 10 seconds, which should be sufficient for most applications.

## Reverting to Default

To stop hooking applications and revert to Windows default:
1. Open X-FSE Hook as Administrator
2. Click the "Default" button in the Presets section
3. This restores the original Windows behavior

## Advanced: Manual Testing

To manually test the wrapper script:

```powershell
# Replace with your actual application path
.\Focus-Application.ps1 -ApplicationPath "C:\Path\To\Your\App.exe"
```

The script will:
- Launch the application
- Report when it successfully brings the window to foreground
- Show any errors if the window can't be focused

## Need Help?

Check the [TECHNICAL-NOTES.md](TECHNICAL-NOTES.md) for detailed implementation information, or open an issue on GitHub.
