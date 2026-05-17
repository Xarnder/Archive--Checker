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
$counter = 1

foreach ($entry in $manifest) {
    $path = $entry.Path
    $expectedHash = $entry.Hash

    Write-Host "Checking $counter of $($manifest.Count): $path"

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "  MISSING" -ForegroundColor Red
        $missingFiles += $path
    }
    else {
        $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash

        if ($actualHash -eq $expectedHash) {
            Write-Host "  OK" -ForegroundColor Green
            $okFiles += $path
        }
        else {
            Write-Host "  CHANGED / CORRUPTED" -ForegroundColor Red
            Write-Host "  Expected: $expectedHash"
            Write-Host "  Actual:   $actualHash"
            $changedFiles += $path
        }
    }

    $counter++
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
        $missingFiles | ForEach-Object { Write-Host $_ }
    }

    if ($changedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Changed or corrupted files:" -ForegroundColor Red
        $changedFiles | ForEach-Object { Write-Host $_ }
    }
}