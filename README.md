# Archive Check

Archive Check is a set of PowerShell scripts designed to help you prepare, hash, and verify files for long-term archiving or transfer. It helps you prevent Windows file path length issues and ensures the integrity of your files over time using SHA-256 checksums.

## Features

1. Path Length Optimization: Detects and automatically renames files with extremely long names (greater than 80 characters) or deep paths (greater than 240 characters) to ensure compatibility with standard Windows zip tools and file systems.
2. SHA-256 Manifest Creation: Computes a unique cryptographic hash for every file in the directory recursively and exports these hashes to a CSV file.
3. Integrity Verification: Verifies existing files against a previously generated manifest to detect missing, modified, or corrupted files.

## Files Included

* create-manifest.ps1: Prepares your files by shortening names where necessary, then generates the SHA-256 hashes and saves them to manifest.csv.
* check-manifest.ps1: Verifies the integrity of files in the folder against the values stored in manifest.csv.

## Setup and System Requirements

* Operating System: Windows
* Environment: Windows PowerShell 5.1 or PowerShell Core 7.0+
* Permissions: You must have permission to run PowerShell scripts on your system.

### Execution Policy
By default, Windows blocks the execution of untrusted scripts. To run these scripts, you may need to adjust your execution policy or run them with a bypass flag.

To run a script with a temporary bypass (recommended):
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File .\create-manifest.ps1
```
Alternatively, you can unblock the scripts in your current session:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## How to Use

### Phase 1: Preparing and Hashing Your Folder

Use this phase before archiving, zipping, or transferring your folder.

1. Copy create-manifest.ps1 into the root folder of the directory you want to process.
2. Open PowerShell and change directory (cd) to that folder.
3. Run the script:
   ```powershell
   .\create-manifest.ps1
   ```
   If execution is blocked, use the bypass command:
   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\create-manifest.ps1
   ```
4. The script will perform two actions:
   * Step 1 (Rename): It scans for files with names longer than 80 characters or total paths longer than 240 characters. If found, it renames them to a safe length while preserving the first 25 characters of their original name and suffixing them with a unique ID (e.g., filename-FIXED-1.ext).
   * Step 2 (Hash): It calculates the SHA-256 checksum for all files (excluding manifest.csv) and saves the results to a file named manifest.csv in the same folder.

You can now compress or transfer the entire directory. Make sure to keep manifest.csv and check-manifest.ps1 inside the folder.

### Phase 2: Verifying Your Archive

Use this phase after extracting, transferring, or retrieving your folder from archives to ensure no files were corrupted or lost.

1. Ensure check-manifest.ps1 and manifest.csv are in the root directory of the files you want to check.
2. Open PowerShell and change directory (cd) to that folder.
3. Run the script. By default, it prints the status of every file. For a faster, quieter run with a progress bar, use the optional `-Fast` parameter:
   * **Standard Mode** (displays every file status):
     ```powershell
     .\check-manifest.ps1
     ```
     Or using the bypass command:
     ```powershell
     PowerShell.exe -ExecutionPolicy Bypass -File .\check-manifest.ps1
     ```
   * **Fast Mode** (hides individual file prints, showing a `tqdm`-style progress bar with progress percentage, remaining time estimate, and processing speed):
     ```powershell
     .\check-manifest.ps1 -Fast
     ```
     Or using the bypass command:
     ```powershell
     PowerShell.exe -ExecutionPolicy Bypass -File .\check-manifest.ps1 -Fast
     ```
4. The script will read manifest.csv and recalculate the SHA-256 hash for every file listed:
   * In standard mode, it prints each file with its status:
     * OK: The file exists and the hash matches perfectly.
     * MISSING: The file was present when the manifest was created but is now missing.
     * CHANGED / CORRUPTED: The file exists but its content has changed.
   * In fast mode, a `tqdm`-style progress bar updates dynamically.

At the end of the run, the script provides a final summary table showing the count of OK, missing, and changed files. If any issues are found, they will be listed at the bottom of the output.
