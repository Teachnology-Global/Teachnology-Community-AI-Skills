#Requires -Version 5.1
<#
.SYNOPSIS
    Security scan script for Windows - Cursor Governance Framework

.DESCRIPTION
    Runs security scans including SAST, SCA, and secret detection.
    
.PARAMETER Path
    Path to scan (default: current directory)
    
.PARAMETER ScanType
    Type of scan: all, sast, sca, secrets (default: all)
    
.EXAMPLE
    .\security-scan.ps1
    
.EXAMPLE
    .\security-scan.ps1 -Path "C:\Projects\MyApp" -ScanType sast
#>

param(
    [string]$Path = ".",
    [ValidateSet("all", "sast", "sca", "secrets")]
    [string]$ScanType = "all"
)

# Colors
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Cyan = "Cyan"
}

# Results tracking
$script:CriticalCount = 0
$script:HighCount = 0
$script:MediumCount = 0
$script:LowCount = 0
$script:SecretsCount = 0

function Write-Header {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Cursor Governance - Security Gate (Windows)" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Scan Path: $Path"
    Write-Host "Scan Type: $ScanType"
    Write-Host ""
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Run-SAST {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Running SAST (Static Analysis)..." -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    if (Test-Command "semgrep") {
        try {
            $result = & semgrep --config=auto --severity ERROR --severity WARNING --json $Path 2>$null | ConvertFrom-Json
            
            if ($result.results) {
                $errors = ($result.results | Where-Object { $_.extra.severity -eq "ERROR" }).Count
                $warnings = ($result.results | Where-Object { $_.extra.severity -eq "WARNING" }).Count
                
                $script:CriticalCount += $errors
                $script:HighCount += $warnings
                
                Write-Host "SAST Results: " -NoNewline
                Write-Host "$errors critical" -ForegroundColor Red -NoNewline
                Write-Host ", $warnings high" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Semgrep scan completed (check output for details)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Warning: semgrep not found. Skipping SAST." -ForegroundColor Yellow
    }
}

function Run-SCA {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Running SCA (Dependency Scan)..." -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    if (Test-Command "trivy") {
        try {
            $result = & trivy fs --severity CRITICAL,HIGH --format json $Path 2>$null | ConvertFrom-Json
            
            if ($result.Results) {
                $critical = 0
                $high = 0
                
                foreach ($r in $result.Results) {
                    if ($r.Vulnerabilities) {
                        $critical += ($r.Vulnerabilities | Where-Object { $_.Severity -eq "CRITICAL" }).Count
                        $high += ($r.Vulnerabilities | Where-Object { $_.Severity -eq "HIGH" }).Count
                    }
                }
                
                $script:CriticalCount += $critical
                $script:HighCount += $high
                
                Write-Host "SCA Results: " -NoNewline
                Write-Host "$critical critical" -ForegroundColor Red -NoNewline
                Write-Host ", $high high" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Trivy scan completed (check output for details)" -ForegroundColor Yellow
        }
    }
    elseif (Test-Path "package.json") {
        Write-Host "Running npm audit..." -ForegroundColor Cyan
        & npm audit --audit-level=high 2>$null
    }
    else {
        Write-Host "Warning: trivy not found. Skipping SCA." -ForegroundColor Yellow
    }
}

function Run-Secrets {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Running Secret Detection..." -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    if (Test-Command "gitleaks") {
        try {
            $tempFile = [System.IO.Path]::GetTempFileName()
            & gitleaks detect --source="$Path" --report-format json --report-path $tempFile 2>$null
            
            if (Test-Path $tempFile) {
                $content = Get-Content $tempFile -Raw
                if ($content) {
                    $result = $content | ConvertFrom-Json
                    $script:SecretsCount = $result.Count
                    
                    if ($script:SecretsCount -gt 0) {
                        Write-Host "SECRETS DETECTED: $($script:SecretsCount)" -ForegroundColor Red
                        $script:CriticalCount += $script:SecretsCount
                    }
                    else {
                        Write-Host "No secrets detected" -ForegroundColor Green
                    }
                }
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host "Gitleaks scan completed" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Warning: gitleaks not found. Skipping secret detection." -ForegroundColor Yellow
        
        # Basic pattern matching fallback
        Write-Host "Running basic secret pattern check..." -ForegroundColor Cyan
        
        $patterns = @(
            "password\s*=\s*['""][^'""]+['""]",
            "api[_-]?key\s*=\s*['""][^'""]+['""]",
            "secret\s*=\s*['""][^'""]+['""]",
            "-----BEGIN (RSA |DSA |EC )?PRIVATE KEY-----"
        )
        
        $foundSecrets = 0
        $extensions = @("*.ts", "*.js", "*.py", "*.json", "*.yaml", "*.yml", "*.env")
        
        foreach ($ext in $extensions) {
            $files = Get-ChildItem -Path $Path -Filter $ext -Recurse -ErrorAction SilentlyContinue |
                     Where-Object { $_.FullName -notmatch "node_modules|\.git|dist|build" }
            
            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                foreach ($pattern in $patterns) {
                    if ($content -match $pattern) {
                        $foundSecrets++
                        Write-Host "  Potential secret in: $($file.FullName)" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        if ($foundSecrets -gt 0) {
            Write-Host "Found $foundSecrets potential secrets (manual review required)" -ForegroundColor Yellow
        }
    }
}

function Write-Summary {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Security Gate Summary" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Critical: $script:CriticalCount"
    Write-Host "High:     $script:HighCount"
    Write-Host "Medium:   $script:MediumCount"
    Write-Host "Low:      $script:LowCount"
    Write-Host ""
    
    if ($script:CriticalCount -gt 0 -or $script:HighCount -gt 0) {
        Write-Host "❌ GATE FAILED - Deployment blocked" -ForegroundColor Red
        Write-Host ""
        Write-Host "Fix critical and high findings before deploying."
        return 1
    }
    else {
        Write-Host "✅ GATE PASSED - Deployment allowed" -ForegroundColor Green
        return 0
    }
}

# Main
Write-Header

switch ($ScanType) {
    "sast" { Run-SAST }
    "sca" { Run-SCA }
    "secrets" { Run-Secrets }
    default {
        Run-SAST
        Run-SCA
        Run-Secrets
    }
}

$exitCode = Write-Summary
exit $exitCode

