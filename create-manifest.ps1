Write-Host "Starting archive preparation..." -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Step 1: Rename files with long paths or long filenames
# ------------------------------------------------------------

Write-Host "Step 1: Checking for long file paths or long file names..." -ForegroundColor Yellow

$longFiles = Get-ChildItem -File -Recurse | Where-Object {
    $_.FullName.Length -gt 240 -or $_.Name.Length -gt 80
}

if ($longFiles.Count -eq 0) {
    Write-Host "No long file names found. Nothing to rename." -ForegroundColor Green
}
else {
    Write-Host "Found $($longFiles.Count) file(s) to rename." -ForegroundColor Yellow
    Write-Host ""

    $counter = 1

    foreach ($file in $longFiles) {
        $keepChars = [math]::Min($file.BaseName.Length, 25)
        $startOfName = $file.BaseName.Substring(0, $keepChars)

        $newName = "$startOfName-FIXED-$counter$($file.Extension)"
        $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName

        while (Test-Path -LiteralPath $newPath) {
            $counter++
            $newName = "$startOfName-FIXED-$counter$($file.Extension)"
            $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName
        }

        Write-Host "Renaming:" -ForegroundColor DarkYellow
        Write-Host "  From: $($file.FullName)"
        Write-Host "  To:   $newPath"
        Write-Host ""

        Rename-Item -LiteralPath $file.FullName -NewName $newName

        $counter++
    }

    Write-Host "Renaming complete." -ForegroundColor Green
}

Write-Host ""

# ------------------------------------------------------------
# Step 2: Create SHA-256 manifest
# ------------------------------------------------------------

Write-Host "Step 2: Creating SHA-256 manifest..." -ForegroundColor Yellow
Write-Host ""

$filesToHash = Get-ChildItem -File -Recurse -Exclude manifest.csv

if ($filesToHash.Count -eq 0) {
    Write-Host "No files found to hash." -ForegroundColor Red
}
else {
    Write-Host "Found $($filesToHash.Count) file(s) to hash." -ForegroundColor Yellow
    Write-Host ""

    $hashResults = foreach ($file in $filesToHash) {
        Write-Host "Hashing: $($file.FullName)"
        Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    }

    $hashResults | Export-Csv -Path manifest.csv -Encoding UTF8 -NoTypeInformation

    Write-Host ""
    Write-Host "Manifest created successfully: manifest.csv" -ForegroundColor Green
}

Write-Host ""
Write-Host "DONE - archive preparation is complete." -ForegroundColor Cyan