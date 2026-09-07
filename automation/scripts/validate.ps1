<#
.SYNOPSIS
    Validation Script for Daily Life Project.

.DESCRIPTION
    Runs all validation checks required by the orchestrator:
    1. Dart format check
    2. Dart analyze
    3. Dart test
    4. Dart compile kernel
    5. Flutter analyze

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
#>
param(
    [switch]$Verbose,
    [int]$MaxRetries = 3
)

$ErrorActionPreference = "Continue"
$script:AllPassed = $true
$script:Results = @{}

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

function Run-ValidationCommand {
    param(
        [string]$Name,
        [string]$Command,
        [string]$WorkDir = "C:\Users\USER\daily_life"
    )

    Write-Log "Running $Name: $Command"
    try {
        $output = & $Command 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "$Name: PASS" "PASS"
            $script:Results[$Name] = "PASS"
            return $true
        } else {
            Write-Log "$Name: FAIL (exit code: $exitCode)" "FAIL"
            if ($Verbose) {
                Write-Host $output
            }
            Write-Log "$Name output: $($output | Select-String -First 5 -SimpleMatch)" "WARN"
            $script:Results[$Name] = "FAIL"
            return $false
        }
    } catch {
        Write-Log "$Name: ERROR - $_" "FAIL"
        $script:Results[$Name] = "ERROR"
        return $false
    }
}

# --- Main Validation ---

function Invoke-AllValidation {
    Write-Log "=== Starting Validation ==="

    # 1. Format check
    Run-ValidationCommand -Name "Format" -Command "dart format --output=none ."

    # 2. Analyze
    Run-ValidationCommand -Name "Analyze" -Command "dart analyze lib/"

    # 3. Test
    Run-ValidationCommand -Name "Test" -Command "dart test"

    # 4. Build
    Run-ValidationCommand -Name "Build" -Command "dart compile kernel lib/main.dart"

    # 5. Flutter analyze
    Run-ValidationCommand -Name "Flutter Analyze" -Command "flutter analyze"

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
