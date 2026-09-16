Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# DroidConverge - Finalizzazione checkpoint/release
# ============================================================
#
# Obiettivi:
#   1. verificare repository + ADB + device
#   2. creare audit/rollback locale prima di modificare qualsiasi cosa
#   3. recuperare dal checkpoint solo i file di progetto noti
#   4. non sovrascrivere mai automaticamente file locali differenti
#   5. mettere i conflitti in checkpoint-recovery\conflicts
#   6. organizzare gli script Termux / Ubuntu
#   7. recuperare i materiali di integrazione Maliit/Plasma Mobile
#   8. proteggere token/segreti e artefatti temporanei
#   9. eseguire git diff --check
#  10. compilare Android Bridge in debug per validazione
#  11. produrre un report finale
#
# NON:
#   - esegue git reset
#   - cancella file di progetto
#   - sovrascrive conflitti
#   - pubblica automaticamente
#   - committa automaticamente
#
# ============================================================

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoRoot

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$AuditRoot = Join-Path $RepoRoot "_checkpoint-audit\$Stamp"
$RecoveryRoot = Join-Path $RepoRoot "checkpoint-recovery\$Stamp"
$ConflictRoot = Join-Path $RecoveryRoot "conflicts"

New-Item -ItemType Directory -Force -Path $AuditRoot | Out-Null
New-Item -ItemType Directory -Force -Path $RecoveryRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ConflictRoot | Out-Null

$Report = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]
$Conflicts = New-Object System.Collections.Generic.List[string]

function Log {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    $script:Report.Add($Message)
}

function Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    $script:Warnings.Add($Message)
}

function Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    $script:Report.Add("ERROR: $Message")
    throw $Message
}

function SameFile {
    param(
        [Parameter(Mandatory)] [string]$A,
        [Parameter(Mandatory)] [string]$B
    )

    if (-not (Test-Path -LiteralPath $A) -or -not (Test-Path -LiteralPath $B)) {
        return $false
    }

    $ha = (Get-FileHash -LiteralPath $A -Algorithm SHA256).Hash
    $hb = (Get-FileHash -LiteralPath $B -Algorithm SHA256).Hash

    return $ha -eq $hb
}

function Copy-Safely {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination,
        [string]$Label = ""
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Warn "Sorgente assente: $Source"
        return
    }

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Log "Importato: $Label -> $Destination"
        return
    }

    if (SameFile -A $Source -B $Destination) {
        Log "Già presente e identico: $Destination"
        return
    }

    $relativeConflict = $Destination.Substring($RepoRoot.Length).TrimStart('\')
    $conflictDestination = Join-Path $ConflictRoot $relativeConflict
    $conflictParent = Split-Path -Parent $conflictDestination
    New-Item -ItemType Directory -Force -Path $conflictParent | Out-Null

    Copy-Item -LiteralPath $Source -Destination $conflictDestination -Force

    $msg = "CONFLITTO: file locale differente, recuperato separatamente -> $conflictDestination"
    Write-Host "[CONFLICT] $msg" -ForegroundColor Magenta
    $script:Conflicts.Add($msg)
}

function Invoke-Adb {
    param([Parameter(Mandatory)] [string[]]$Arguments)

    $output = & $script:Adb @Arguments 2>&1
    $code = $LASTEXITCODE

    return [PSCustomObject]@{
        Code = $code
        Output = ($output -join "`n")
    }
}

function Pull-FromDevice {
    param(
        [Parameter(Mandatory)] [string]$Remote,
        [Parameter(Mandatory)] [string]$Local
    )

    $parent = Split-Path -Parent $Local
    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    $r = Invoke-Adb @("pull", $Remote, $Local)

    if ($r.Code -ne 0) {
        throw "adb pull fallito: $Remote`n$($r.Output)"
    }

    return $Local
}

function Pull-TarMember {
    param(
        [Parameter(Mandatory)] [string]$Tar,
        [Parameter(Mandatory)] [string]$Member,
        [Parameter(Mandatory)] [string]$Local
    )

    $tempDevice = "/data/local/tmp/droidconverge-finalize-$([guid]::NewGuid().ToString('N'))"
    $remoteFile = "$tempDevice/" + ([IO.Path]::GetFileName($Member))

    $mk = Invoke-Adb @("shell", "mkdir -p '$tempDevice'")
    if ($mk.Code -ne 0) {
        throw "Impossibile creare area temporanea sul device."
    }

    try {
        $cmd = "tar -xOf '$Tar' '$Member' > '$remoteFile'"
        $rx = Invoke-Adb @("shell", "sh", "-c", $cmd)

        if ($rx.Code -ne 0) {
            throw "Impossibile estrarre '$Member' dal backup.`n$($rx.Output)"
        }

        Pull-FromDevice -Remote $remoteFile -Local $Local | Out-Null
    }
    finally {
        Invoke-Adb @("shell", "rm", "-rf", $tempDevice) | Out-Null
    }
}

# ============================================================
# 1. Repository
# ============================================================

Log "Repository: $RepoRoot"

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
    Fail "La directory corrente non è la root di un repository Git."
}

$head = (& git log -1 --oneline 2>&1 | Out-String).Trim()
Log "HEAD: $head"

$statusBefore = (& git status --short 2>&1 | Out-String).Trim()
if ($statusBefore) {
    Log "Working tree non pulito: verrà preservato, non sovrascritto."
} else {
    Log "Working tree pulito."
}

# ============================================================
# 2. Audit locale prima di qualsiasi import
# ============================================================

Log "Creo snapshot dei file modificati/non tracciati."

$gitDiffPath = Join-Path $AuditRoot "git-diff.patch"
& git diff --binary | Out-File -FilePath $gitDiffPath -Encoding utf8

$trackedModified = & git diff --name-only
$untracked = & git ls-files --others --exclude-standard

$manifestPath = Join-Path $AuditRoot "working-tree-manifest.txt"

@(
    "DATE=$([DateTime]::Now.ToString('o'))"
    "HEAD=$head"
    "---- MODIFIED ----"
    $trackedModified
    "---- UNTRACKED ----"
    $untracked
) | Out-File -FilePath $manifestPath -Encoding utf8

foreach ($relative in $trackedModified) {
    if ([string]::IsNullOrWhiteSpace($relative)) { continue }

    $src = Join-Path $RepoRoot $relative
    if (Test-Path -LiteralPath $src -PathType Leaf) {
        $dst = Join-Path $AuditRoot "working-tree\$relative"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

foreach ($relative in $untracked) {
    if ([string]::IsNullOrWhiteSpace($relative)) { continue }

    # Evita di ricopiare il nostro stesso audit
    if ($relative -like "_checkpoint-audit\*") { continue }

    $src = Join-Path $RepoRoot $relative
    if (Test-Path -LiteralPath $src -PathType Leaf) {
        $dst = Join-Path $AuditRoot "working-tree\$relative"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

Log "Audit locale creato in: $AuditRoot"

# ============================================================
# 3. ADB
# ============================================================

if ($env:ADB -and (Test-Path -LiteralPath $env:ADB)) {
    $Adb = $env:ADB
}
elseif (Get-Command adb.exe -ErrorAction SilentlyContinue) {
    $Adb = (Get-Command adb.exe).Source
}
elseif (Test-Path "C:\Users\Ciro\Desktop\platform-tools\adb.exe") {
    $Adb = "C:\Users\Ciro\Desktop\platform-tools\adb.exe"
}
else {
    Fail "ADB non trovato."
}

Log "ADB: $Adb"

$adbDevices = Invoke-Adb @("devices")
if ($adbDevices.Code -ne 0) {
    Fail "ADB non risponde."
}

$deviceLines = $adbDevices.Output -split "`r?`n" |
    Where-Object { $_ -match "\sdevice$" }

if ($deviceLines.Count -lt 1) {
    Fail "Nessun dispositivo Android autorizzato rilevato."
}

if ($deviceLines.Count -gt 1) {
    Warn "Rilevati più dispositivi ADB; verrà usato il primo."
}

$Device = ($deviceLines | Select-Object -First 1).Split("`t")[0]
Log "Device: $Device"

# ============================================================
# 4. Verifica checkpoint
# ============================================================

$Checkpoint = "/sdcard/DroidConverge-backups/droidconverge-ubuntu-snapshot"
$TermuxTar = "/sdcard/DroidConverge-backups/droidconverge-termux-2026-09-15.tar"
$CheckpointTar = "/sdcard/DroidConverge-backups/droidconverge-ubuntu-snapshot-2026-09-15.tar"

foreach ($remote in @($Checkpoint, $TermuxTar, $CheckpointTar)) {
    $test = Invoke-Adb @("shell", "test", "-e", $remote)
    if ($test.Code -ne 0) {
        Fail "Checkpoint richiesto non trovato sul device: $remote"
    }
}

Log "Checkpoint Ubuntu + Termux verificati."

# ============================================================
# 5. Recupero mirato Termux
# ============================================================

$TermuxMembers = @(
    "anland-bridge.sh",
    "anland-haptic-test",
    "start-ubuntu-kde.sh",
    "startplasma-anland.sh",
    ".shortcuts/tasks/Ubuntu-KDE",
    ".termux/tasker/haptic"
)

$TermuxStage = Join-Path $RecoveryRoot "termux"
New-Item -ItemType Directory -Force -Path $TermuxStage | Out-Null

foreach ($member in $TermuxMembers) {
    $local = Join-Path $TermuxStage ($member -replace '/', '\')
    Pull-TarMember -Tar $TermuxTar -Member $member -Local $local | Out-Null
}

# Mapping nel repository
$TermuxMap = @{
    "anland-bridge.sh"              = "scripts/termux/anland-bridge.sh"
    "anland-haptic-test"            = "scripts/termux/anland-haptic-test"
    "start-ubuntu-kde.sh"           = "scripts/termux/start-ubuntu-kde.sh"
    "startplasma-anland.sh"         = "scripts/termux/startplasma-anland.sh"
    ".shortcuts/tasks/Ubuntu-KDE"    = "scripts/termux/shortcuts/tasks/Ubuntu-KDE"
    ".termux/tasker/haptic"         = "scripts/termux/tasker/haptic"
}

foreach ($pair in $TermuxMap.GetEnumerator()) {
    $source = Join-Path $TermuxStage ($pair.Key -replace '/', '\')
    $destination = Join-Path $RepoRoot $pair.Value
    Copy-Safely -Source $source -Destination $destination -Label "Termux/$($pair.Key)"
}

# ============================================================
# 6. Recupero mirato Ubuntu
# ============================================================

$UbuntuMembers = @(
    "scripts/home/android/desktop-mode.sh",
    "scripts/home/android/kwin-tablet-mode.py",
    "scripts/home/android/on-off-switch-plasmoid/Plasmoid-switch-on-off-button.sh",
    "scripts/home/android/reset-plasma-default.sh",
    "scripts/home/android/setup-plasma-modes-v2.sh",
    "scripts/home/android/setup-plasma-modes.sh",
    "scripts/home/android/start-anland-plasma.sh",
    "scripts/home/android/tablet-mode.sh",
    "scripts/home/android/toggle-tablet-mode.sh",
    "scripts/home/android/true-tablet-mode.sh",
    "scripts/local-bin/plasma-desktop-mode",
    "scripts/local-bin/plasma-toggle-mode",
    "scripts/local-bin/plasma-touch-mode",
    "configs/droidconverge.json.example"
)

$UbuntuStage = Join-Path $RecoveryRoot "ubuntu"
New-Item -ItemType Directory -Force -Path $UbuntuStage | Out-Null

foreach ($member in $UbuntuMembers) {
    Pull-FromDevice `
        -Remote "$Checkpoint/$member" `
        -Local (Join-Path $UbuntuStage ($member -replace '/', '\')) |
        Out-Null
}

foreach ($member in $UbuntuMembers) {
    $source = Join-Path $UbuntuStage ($member -replace '/', '\')

    switch -Regex ($member) {
        '^scripts/home/android/on-off-switch-plasmoid/' {
            $destRelative = "scripts/ubuntu/plasmoids/on-off-switch/Plasmoid-switch-on-off-button.sh"
        }
        '^scripts/home/android/(.*)$' {
            $destRelative = "scripts/ubuntu/$($Matches[1])"
        }
        '^scripts/local-bin/(.*)$' {
            $destRelative = "scripts/ubuntu/bin/$($Matches[1])"
        }
        '^configs/(.*)$' {
            $destRelative = "configs/$($Matches[1])"
        }
        default {
            Warn "Mapping Ubuntu non riconosciuto: $member"
            continue
        }
    }

    $destination = Join-Path $RepoRoot $destRelative
    Copy-Safely -Source $source -Destination $destination -Label "Ubuntu/$member"
}

# ============================================================
# 7. Materiale Maliit / Plasma Mobile
# ============================================================

$PatchStage = Join-Path $RecoveryRoot "patches"
New-Item -ItemType Directory -Force -Path $PatchStage | Out-Null

$MaliitMembers = @(
    "maliit/backup/CMakeLists.txt.before-tcp",
    "maliit/backup/feedback.cpp.before-tcp",
    "maliit/backup/feedback.cpp",
    "maliit/backup/feedback.h"
)

foreach ($member in $MaliitMembers) {
    Pull-FromDevice `
        -Remote "$Checkpoint/$member" `
        -Local (Join-Path $PatchStage ($member -replace '/', '\')) |
        Out-Null
}

# Genera patch se le due versioni sono disponibili.
$MaliitBefore = Join-Path $PatchStage "maliit\backup\feedback.cpp.before-tcp"
$MaliitAfter  = Join-Path $PatchStage "maliit\backup\feedback.cpp"
$MaliitPatch  = Join-Path $RepoRoot "patches\maliit\feedback-droidconverge.patch"

if ((Test-Path $MaliitBefore) -and (Test-Path $MaliitAfter)) {
    $before = Get-Content -LiteralPath $MaliitBefore
    $after  = Get-Content -LiteralPath $MaliitAfter

    $diffFile = Join-Path $PatchStage "maliit-feedback.diff"

    # fc.exe non è garantito; produciamo comunque un confronto leggibile.
    $comparison = Compare-Object -ReferenceObject $before -DifferenceObject $after -SyncWindow 0 |
        ForEach-Object {
            if ($_.SideIndicator -eq '<=') {
                "-$($_.InputObject)"
            }
            else {
                "+$($_.InputObject)"
            }
        }

    @(
        "# DroidConverge Maliit feedback.cpp delta"
        "# Generated from checkpoint recovery on $([DateTime]::Now.ToString('o'))"
        ""
        $comparison
    ) | Set-Content -LiteralPath $diffFile -Encoding utf8

    New-Item -ItemType Directory -Force -Path (Split-Path $MaliitPatch) | Out-Null

    if (-not (Test-Path -LiteralPath $MaliitPatch)) {
        Copy-Item -LiteralPath $diffFile -Destination $MaliitPatch -Force
        Log "Patch Maliit recuperata in $MaliitPatch"
    }
    elseif (SameFile -A $diffFile -B $MaliitPatch) {
        Log "Patch Maliit già presente e identica."
    }
    else {
        $conf = Join-Path $ConflictRoot "patches\maliit\feedback-droidconverge.patch"
        New-Item -ItemType Directory -Force -Path (Split-Path $conf) | Out-Null
        Copy-Item -LiteralPath $diffFile -Destination $conf -Force
        $Conflicts.Add("Patch Maliit locale differente: $conf")
    }
}

# Conserva il materiale sorgente di audit, ma non lo promuove nel repo.
Log "Materiale Maliit conservato nello staging di recovery."

# ============================================================
# 8. .gitignore: solo artefatti temporanei noti
# ============================================================

$GitIgnore = Join-Path $RepoRoot ".gitignore"

$RequiredIgnore = @(
    "# DroidConverge checkpoint/release temporary artifacts",
    "checkpoint-recovery/",
    "_checkpoint-audit/",
    "*.bak"
)

$currentIgnore = if (Test-Path -LiteralPath $GitIgnore) {
    Get-Content -LiteralPath $GitIgnore
}
else {
    @()
}

foreach ($entry in $RequiredIgnore) {
    if ($currentIgnore -notcontains $entry) {
        Add-Content -LiteralPath $GitIgnore -Value $entry
        Log "Aggiunta regola .gitignore: $entry"
    }
}

# ============================================================
# 9. Controllo encoding evidente nei file recuperati
# ============================================================

$PotentialTextFiles = Get-ChildItem -Path @(
    (Join-Path $RepoRoot "scripts"),
    (Join-Path $RepoRoot "configs"),
    (Join-Path $RepoRoot "patches")
) -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in ".sh",".bash",".py",".conf",".json",".patch",".txt" }

foreach ($file in $PotentialTextFiles) {
    $raw = [IO.File]::ReadAllText($file.FullName)

    if ($raw -match "Ã[^\r\n]{0,3}[^\r\n]*|â€“|â€”|â€œ|â€|giÃ |Ã¨|Ã ") {
        Warn "Possibile mojibake rilevato: $($file.FullName)"
    }
}

# ============================================================
# 10. Controllo segreti
# ============================================================

$SecretMatches = @()

$SearchRoots = @(
    (Join-Path $RepoRoot "scripts"),
    (Join-Path $RepoRoot "configs"),
    (Join-Path $RepoRoot "docs"),
    (Join-Path $RepoRoot "patches"),
    (Join-Path $RepoRoot "DroidConvergeBridge")
)

foreach ($root in $SearchRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }

    $files = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        if ($file.FullName -match "\\(build|\.gradle|\.git)\\") { continue }

        try {
            $text = [IO.File]::ReadAllText($file.FullName)
        }
        catch {
            continue
        }

        if ($text -match '"haptic_token"\s*:\s*"(?!(CHANGE_ME|YOUR_TOKEN|REPLACE_ME|\$\{[^}]+\}|"?))[^"]{20,}"') {
            $SecretMatches += $file.FullName
        }
    }
}

if ($SecretMatches.Count -gt 0) {
    foreach ($s in $SecretMatches) {
        Warn "POSSIBILE TOKEN/SEGRETO: $s"
    }

    Fail "Trovati possibili segreti. Finalizzazione interrotta prima della pubblicazione."
}

Log "Controllo segreti: OK."

# ============================================================
# 11. Verifica file fondamentali progetto
# ============================================================

$ExpectedPaths = @(
    "README.md",
    "CHANGELOG.md",
    "SECURITY.md",
    "docs/INSTALLATION.md",
    "docs/PROJECT-STATUS.md",
    "DroidConvergeBridge/gradlew.bat",
    "DroidConvergeBridge/app/build.gradle.kts",
    "scripts/termux/start-ubuntu-kde.sh",
    "scripts/termux/startplasma-anland.sh",
    "scripts/termux/anland-bridge.sh",
    "scripts/ubuntu/start-anland-plasma.sh",
    "configs/droidconverge.json.example"
)

foreach ($relative in $ExpectedPaths) {
    $path = Join-Path $RepoRoot $relative
    if (-not (Test-Path -LiteralPath $path)) {
        Warn "File/progetto atteso non presente: $relative"
    }
}

# ============================================================
# 12. Git diff --check
# ============================================================

Log "Eseguo git diff --check..."

$diffCheck = & git diff --check 2>&1
if ($LASTEXITCODE -ne 0) {
    $diffCheck | ForEach-Object {
        Warn "git diff --check: $_"
    }
}
else {
    Log "git diff --check: OK."
}

# ============================================================
# 13. Build Android Bridge
# ============================================================

$Gradle = Join-Path $RepoRoot "DroidConvergeBridge\gradlew.bat"

if (Test-Path -LiteralPath $Gradle) {
    Log "Avvio build Android Bridge: assembleDebug"

    Push-Location (Join-Path $RepoRoot "DroidConvergeBridge")
    try {
        & $Gradle assembleDebug

        if ($LASTEXITCODE -ne 0) {
            Fail "Build Android Bridge fallita."
        }

        Log "Build Android Bridge: OK."
    }
    finally {
        Pop-Location
    }
}
else {
    Warn "gradlew.bat non trovato: build Android saltata."
}

# ============================================================
# 14. Stato finale
# ============================================================

$statusAfter = (& git status --short 2>&1 | Out-String).Trim()

$FinalReport = Join-Path $RepoRoot "droidconverge-finalization-review.txt"

@(
    "DroidConverge finalization report"
    "================================"
    "Date: $([DateTime]::Now.ToString('o'))"
    "Repository: $RepoRoot"
    "HEAD: $head"
    ""
    "Audit:"
    "  $AuditRoot"
    ""
    "Recovery:"
    "  $RecoveryRoot"
    ""
    "Conflicts: $($Conflicts.Count)"
    "Warnings: $($Warnings.Count)"
    ""
    "===== CONFLICTS ====="
    if ($Conflicts.Count -eq 0) { "NONE" } else { $Conflicts }
    ""
    "===== WARNINGS ====="
    if ($Warnings.Count -eq 0) { "NONE" } else { $Warnings }
    ""
    "===== FINAL GIT STATUS ====="
    if ([string]::IsNullOrWhiteSpace($statusAfter)) { "CLEAN" } else { $statusAfter }
) | Set-Content -LiteralPath $FinalReport -Encoding utf8

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "DroidConverge finalizzazione terminata" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Audit       : $AuditRoot"
Write-Host "Recovery    : $RecoveryRoot"
Write-Host "Conflicts   : $($Conflicts.Count)"
Write-Host "Warnings    : $($Warnings.Count)"
Write-Host "Report      : $FinalReport"
Write-Host ""

if ($Conflicts.Count -gt 0) {
    Write-Host "ATTENZIONE: ci sono conflitti da esaminare." -ForegroundColor Yellow
}
else {
    Write-Host "Nessun conflitto automatico rilevato." -ForegroundColor Green
}

Write-Host ""
Write-Host "Il repository NON è stato committato né pushato automaticamente."
Write-Host "Nessun file esistente è stato sovrascritto se differente."
Write-Host ""