<#
.SYNOPSIS
    Validation Script for Daily Life Project.

.DESCRIPTION
    Runs all validation checks required by the orchestrator:
    1. Dart format check
    2. Dart analyze
    3. Flutter test (uses Flutter test runner)
    4. Flutter build (compile check via `flutter build bundle`)

    Returns exit code 0 if all pass, 1 if any fail.
    Has safe failure handling and explicit result reporting.

.EXAMPLE
    .\validate.ps1
    Run all validation checks.

.EXAMPLE
    .\validate.ps1 -Verbose
    Run validation with detailed output.

.NOTES
    Validation must pass before commit.
    Any failure triggers the fix/retry cycle.
    Maximum retries: 3 per validation stage.
    Uses flutter test (not dart test) because dart test pulls in the
    Flutter framework which triggers SDK compatibility errors in this
    environment. flutter test exercises the same test suite correctly.
#>
param(
    [switch]$Verbose,
    [int]$MaxRetries = 3
)

$ErrorActionPreference = "Continue"
$script:AllPassed = $true
$script:Results = @{}
$script:RootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $script:RootDir) { $script:RootDir = (Get-Location).Path }

# --- Helpers ---

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "PASS" { "[PASS]" }
        "FAIL" { "[FAIL]" }
        "WARN" { "[WARN]" }
        default { "[INFO]" }
    }
    Write-Host "$timestamp $prefix $Message"
}

function Invoke-Check {
    param(
        [string]$Name,
        [string]$Command,
        [array]$Arguments
    )

    Write-Log "Running ${Name}: $Command $($Arguments -join ' ')" "INFO"
    try {
        if ($Arguments.Count -gt 0) {
            $output = & $Command @Arguments 2>&1
        } else {
            $output = & $Command 2>&1
        }
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "${Name}: PASS" "PASS"
            $script:Results[$Name] = "PASS"
            return $true
        } else {
            Write-Log "${Name}: FAIL (exit code: $exitCode)" "FAIL"
            if ($Verbose) {
                $output | ForEach-Object { Write-Host $_ }
            } else {
                $output | Select-Object -First 5 | ForEach-Object { Write-Log "$_" "WARN" }
            }
            $script:Results[$Name] = "FAIL"
            return $false
        }
    } catch {
        Write-Log "${Name}: ERROR - $_" "FAIL"
        $script:Results[$Name] = "ERROR"
        return $false
    }
}

# --- Main Validation ---

function Invoke-AllValidation {
    Write-Log "=== Starting Validation ==="

    # 1. Format check
    Invoke-Check -Name "Format" -Command "dart" -Arguments @("format","--output=none",".")

    # 2. Analyze
    Invoke-Check -Name "Analyze" -Command "dart" -Arguments @("analyze","lib/")

    # 3. Test (flutter test)
    Invoke-Check -Name "Test" -Command "flutter" -Arguments @("test")

    # 4. Build (real Flutter compile check). `flutter build bundle` compiles the
    #    app's Dart into a kernel bundle without requiring a mobile SDK. It is a
    #    valid compile check in this environment; standalone `dart compile`
    #    cannot compile Flutter code (no dart:ui).
    Invoke-Check -Name "Build" -Command "flutter" -Arguments @("build","bundle")

    Write-Log "=== Validation Complete ==="

    # Summary
    $passed = ($script:Results.Values | Where-Object { $_ -eq "PASS" }).Count
    $failed = ($script:Results.Values | Where-Object { $_ -ne "PASS" }).Count
    $total = $script:Results.Count

    Write-Log "Summary: $passed passed, $failed failed, $total total"

    if ($failed -eq 0) {
        Write-Log "All validation checks passed!" "PASS"
        return $true
    } else {
        Write-Log "Some validation checks failed." "FAIL"
        return $false
    }
}

# --- Retry Logic ---

function Invoke-ValidationWithRetry {
    param([int]$MaxRetries = 3)

    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        $attempt++
        Write-Log "Validation attempt $attempt of $MaxRetries"

        $result = Invoke-AllValidation
        if ($result) {
            return $true
        }

        if ($attempt -lt $MaxRetries) {
            Write-Log "Validation failed. Waiting before retry..." "WARN"
            Start-Sleep -Seconds 5
        }
    }

    Write-Log "Validation failed after $MaxRetries attempts." "FAIL"
    return $false
}

# --- Entry Point ---

try {
    Write-Log "Starting validation with max retries: $MaxRetries"

    $result = Invoke-ValidationWithRetry -MaxRetries $MaxRetries

    if ($result) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Log "Validation encountered fatal error: $_" "FAIL"
    exit 1
}
