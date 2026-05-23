param(
    [switch]$Fast
)

# Enable UTF-8 encoding for console output to properly render progress bar characters
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Format-Duration($seconds) {
    if ([double]::IsNaN($seconds) -or [double]::IsInfinity($seconds) -or $seconds -lt 0) {
        return "--:--"
    }
    $ts = [TimeSpan]::FromSeconds($seconds)
    if ($ts.TotalHours -ge 1) {
        return "{0:d2}:{1:d2}:{2:d2}" -f [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds
    } else {
        return "{0:d2}:{1:d2}" -f $ts.Minutes, $ts.Seconds
    }
}

function Update-ProgressBar($current, $total, $stopwatch) {
    $percent = 0
    if ($total -gt 0) {
        $percent = [math]::Min(100, [math]::Max(0, [math]::Round(($current / $total) * 100)))
    }
    
    $barWidth = 30
    $completedBlocks = 0
    if ($total -gt 0) {
        $completedBlocks = [math]::Min($barWidth, [math]::Max(0, [math]::Floor(($current / $total) * $barWidth)))
    }
    $remainingBlocks = $barWidth - $completedBlocks
    $bar = ("#" * $completedBlocks) + (" " * $remainingBlocks)
    
    $elapsed = $stopwatch.Elapsed
    $elapsedSec = $elapsed.TotalSeconds
    
    if ($elapsedSec -gt 0 -and $current -gt 0) {
        $rate = $current / $elapsedSec
        if ($rate -ge 1) {
            $rateStr = "{0:F2}it/s" -f $rate
        } else {
            $rateStr = "{0:F2}s/it" -f (1 / $rate)
        }
        $etaSec = ($total - $current) / $rate
    } else {
        $rateStr = "?it/s"
        $etaSec = -1
    }
    
    $elapsedStr = Format-Duration $elapsedSec
    $etaStr = Format-Duration $etaSec
    
    $progressText = "`r {0,3}%|{1}| {2}/{3} [{4}<{5}, {6}]" -f $percent, $bar, $current, $total, $elapsedStr, $etaStr, $rateStr
    
    # Pad right to clear previous outputs in the same line
    $progressText = $progressText.PadRight(79).Substring(0, 79)
    
    Write-Host -NoNewline $progressText
}

Write-Host "Starting manifest verification..." -ForegroundColor Cyan
Write-Host ""

$manifestPath = ".\manifest.csv"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Host "ERROR: manifest.csv was not found in this folder." -ForegroundColor Red
    Write-Host "Make sure you run this script from the same folder as manifest.csv."
    exit
}

$manifest = Import-Csv -LiteralPath $manifestPath

if ($manifest.Count -eq 0) {
    Write-Host "ERROR: manifest.csv is empty." -ForegroundColor Red
    exit
}

Write-Host "Found $($manifest.Count) file(s) in manifest.csv." -ForegroundColor Yellow
Write-Host ""

$missingFiles = @()
$changedFiles = @()
$okFiles = @()
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$counter = 1

if ($Fast) {
    Update-ProgressBar 0 $manifest.Count $stopwatch
}

foreach ($entry in $manifest) {
    $path = $entry.Path
    $expectedHash = $entry.Hash

    if (-not $Fast) {
        Write-Host "Checking $counter of $($manifest.Count): $path"
    }

    if (-not (Test-Path -LiteralPath $path)) {
        if (-not $Fast) {
            Write-Host "  MISSING" -ForegroundColor Red
        }
        $missingFiles += $path
    }
    else {
        $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash

        if ($actualHash -eq $expectedHash) {
            if (-not $Fast) {
                Write-Host "  OK" -ForegroundColor Green
            }
            $okFiles += $path
        }
        else {
            if (-not $Fast) {
                Write-Host "  CHANGED / CORRUPTED" -ForegroundColor Red
                Write-Host "  Expected: $expectedHash"
                Write-Host "  Actual:   $actualHash"
            }
            $changedFiles += $path
        }
    }

    if ($Fast) {
        Update-ProgressBar $counter $manifest.Count $stopwatch
    }
    $counter++
}

if ($Fast) {
    Write-Host ""
}

Write-Host ""
Write-Host "Verification complete." -ForegroundColor Cyan
Write-Host ""

Write-Host "OK files:       $($okFiles.Count)" -ForegroundColor Green
Write-Host "Missing files:  $($missingFiles.Count)" -ForegroundColor Red
Write-Host "Changed files:  $($changedFiles.Count)" -ForegroundColor Red
Write-Host ""

if ($missingFiles.Count -eq 0 -and $changedFiles.Count -eq 0) {
    Write-Host "SUCCESS - all files match the manifest." -ForegroundColor Green
}
else {
    Write-Host "WARNING - some files are missing or have changed." -ForegroundColor Red

    if ($missingFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Missing files:" -ForegroundColor Red
        $missingFiles | ForEach-Object {
            $fileName = Split-Path -Leaf $_
            Write-Host "  - File: $fileName"
            Write-Host "    Path: $_"
        }
    }

    if ($changedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Changed or corrupted files:" -ForegroundColor Red
        $changedFiles | ForEach-Object {
            $fileName = Split-Path -Leaf $_
            Write-Host "  - File: $fileName"
            Write-Host "    Path: $_"
        }
    }
}