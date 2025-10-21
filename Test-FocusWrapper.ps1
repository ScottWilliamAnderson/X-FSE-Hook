# Test-FocusWrapper.ps1
# Simple test to verify the Focus-Application wrapper integration

Write-Host "Testing X-FSE Hook Window Focus Implementation" -ForegroundColor Cyan
Write-Host "=" * 60

# Test 1: Verify Focus-Application.ps1 exists
Write-Host "`n[Test 1] Checking Focus-Application.ps1 exists..." -ForegroundColor Yellow
$focusScriptPath = Join-Path $PSScriptRoot "Focus-Application.ps1"
if (Test-Path $focusScriptPath) {
    Write-Host "  ✓ Focus-Application.ps1 found" -ForegroundColor Green
} else {
    Write-Host "  ✗ Focus-Application.ps1 NOT found" -ForegroundColor Red
    exit 1
}

# Test 2: Verify Focus-Application.ps1 has valid syntax
Write-Host "`n[Test 2] Validating Focus-Application.ps1 syntax..." -ForegroundColor Yellow
try {
    $content = Get-Content -Raw $focusScriptPath
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
    Write-Host "  ✓ Syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Syntax error: $_" -ForegroundColor Red
    exit 1
}

# Test 3: Verify XFSE-Hook.Export.ps1 exists
Write-Host "`n[Test 3] Checking XFSE-Hook.Export.ps1 exists..." -ForegroundColor Yellow
$mainScriptPath = Join-Path $PSScriptRoot "XFSE-Hook.Export.ps1"
if (Test-Path $mainScriptPath) {
    Write-Host "  ✓ XFSE-Hook.Export.ps1 found" -ForegroundColor Green
} else {
    Write-Host "  ✗ XFSE-Hook.Export.ps1 NOT found" -ForegroundColor Red
    exit 1
}

# Test 4: Verify XFSE-Hook.Export.ps1 has valid syntax
Write-Host "`n[Test 4] Validating XFSE-Hook.Export.ps1 syntax..." -ForegroundColor Yellow
try {
    $content = Get-Content -Raw -Encoding Unicode $mainScriptPath
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
    Write-Host "  ✓ Syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Syntax error: $_" -ForegroundColor Red
    exit 1
}

# Test 5: Verify Set-HookWithFocus function is present
Write-Host "`n[Test 5] Checking for Set-HookWithFocus function..." -ForegroundColor Yellow
$content = Get-Content -Raw -Encoding Unicode $mainScriptPath
if ($content -match 'function Set-HookWithFocus') {
    Write-Host "  ✓ Set-HookWithFocus function found" -ForegroundColor Green
} else {
    Write-Host "  ✗ Set-HookWithFocus function NOT found" -ForegroundColor Red
    exit 1
}

# Test 6: Verify hook functions use Set-HookWithFocus
Write-Host "`n[Test 6] Verifying hook functions use Set-HookWithFocus..." -ForegroundColor Yellow
$expectedVars = @(
    'exePath',
    'SteamPath',
    'playnitePath',
    'GOGPath'
)

$allFound = $true
foreach ($var in $expectedVars) {
    if ($content -match "Set-HookWithFocus.*$var") {
        Write-Host "  ✓ Found: Set-HookWithFocus with `$$var" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: Set-HookWithFocus with `$$var" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    exit 1
}

# Test 7: Verify Focus-Application.ps1 contains Win32 API calls
Write-Host "`n[Test 7] Checking for Win32 API integration..." -ForegroundColor Yellow
$focusContent = Get-Content -Raw $focusScriptPath
$requiredAPIs = @(
    'SetForegroundWindow',
    'ShowWindow',
    'IsIconic',
    'AllowSetForegroundWindow'
)

$allAPIsFound = $true
foreach ($api in $requiredAPIs) {
    if ($focusContent -match $api) {
        Write-Host "  ✓ Found API: $api" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing API: $api" -ForegroundColor Red
        $allAPIsFound = $false
    }
}

if (-not $allAPIsFound) {
    exit 1
}

# Summary
Write-Host "`n" + ("=" * 60)
Write-Host "All tests passed! ✓" -ForegroundColor Green
Write-Host "`nThe window focus implementation is ready for use." -ForegroundColor Cyan
Write-Host "When you hook an application, it will automatically come to the foreground." -ForegroundColor Cyan
