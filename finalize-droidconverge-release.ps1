$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = (Get-Location).Path
$Checkpoint = Join-Path $Repo 'checkpoint-recovery'
$Termux = Join-Path $Root "checkpoint-recovery\termux\droidconverge-recovery"
$Ubuntu = Join-Path $Checkpoint 'ubuntu'
$Android = Join-Path $Repo 'DroidConvergeBridge'

function Write-Section([string]$Text) { Write-Host "`n===== $Text =====" -ForegroundColor Cyan }
function Ensure-Dir([string]$Path) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
function Copy-File([string]$From, [string]$To) {
    Ensure-Dir (Split-Path -Parent $To)
    Copy-Item -LiteralPath $From -Destination $To -Force
}

Write-Section 'CHECKPOINT INTEGRATION'

if (-not (Test-Path $Termux)) { throw "Checkpoint Termux non trovato: $Termux" }
if (-not (Test-Path $Ubuntu)) { throw "Checkpoint Ubuntu non trovato: $Ubuntu" }

# Clean project-specific destination directories from an earlier partial recovery only.
Ensure-Dir (Join-Path $Repo 'scripts\termux')
Ensure-Dir (Join-Path $Repo 'scripts\ubuntu')
Ensure-Dir (Join-Path $Repo 'scripts\install')
Ensure-Dir (Join-Path $Repo 'patches\maliit')
Ensure-Dir (Join-Path $Repo 'configs')

# Termux integration scripts.
@(
    'anland-bridge.sh',
    'anland-haptic-test',
    'start-ubuntu-kde.sh',
    'startplasma-anland.sh'
) | ForEach-Object {
    Copy-File (Join-Path $Termux $_) (Join-Path $Repo "scripts\termux\$_")
}
Copy-File (Join-Path $Termux '.shortcuts\tasks\Ubuntu-KDE') (Join-Path $Repo 'scripts\termux\.shortcuts\tasks\Ubuntu-KDE')
Copy-File (Join-Path $Termux '.termux\tasker\haptic') (Join-Path $Repo 'scripts\termux\.termux\tasker\haptic')

# Ubuntu / KDE integration scripts.
$ubuntuHomeScripts = @(
    'desktop-mode.sh',
    'kwin-tablet-mode.py',
    'reset-plasma-default.sh',
    'setup-plasma-modes-v2.sh',
    'setup-plasma-modes.sh',
    'start-anland-plasma.sh',
    'tablet-mode.sh',
    'toggle-tablet-mode.sh',
    'true-tablet-mode.sh'
)
foreach ($name in $ubuntuHomeScripts) {
    Copy-File (Join-Path $Ubuntu "scripts\home\android\$name") (Join-Path $Repo "scripts\ubuntu\$name")
}
Copy-File (Join-Path $Ubuntu 'scripts\home\android\on-off-switch-plasmoid\Plasmoid-switch-on-off-button.sh') (Join-Path $Repo 'scripts\ubuntu\on-off-switch-plasmoid\Plasmoid-switch-on-off-button.sh')
Copy-File (Join-Path $Ubuntu 'scripts\local-bin\plasma-desktop-mode') (Join-Path $Repo 'scripts\ubuntu\bin\plasma-desktop-mode')
Copy-File (Join-Path $Ubuntu 'scripts\local-bin\plasma-toggle-mode') (Join-Path $Repo 'scripts\ubuntu\bin\plasma-toggle-mode')
Copy-File (Join-Path $Ubuntu 'scripts\local-bin\plasma-touch-mode') (Join-Path $Repo 'scripts\ubuntu\bin\plasma-touch-mode')
Copy-File (Join-Path $Ubuntu 'configs\droidconverge.json.example') (Join-Path $Repo 'configs\droidconverge.json.example')

# Generate a source patch from the tablet checkpoint instead of committing upstream source trees.
$before = Join-Path $Ubuntu 'maliit\backup\feedback.cpp.before-tcp'
$after  = Join-Path $Ubuntu 'maliit\backup\feedback.cpp'
$patch  = Join-Path $Repo 'patches\maliit\0001-droidconverge-haptic-tcp.patch'
& git diff --no-index --no-prefix -- $before $after | Out-File -FilePath $patch -Encoding utf8
$global:LASTEXITCODE = 0

@'
# DroidConverge Maliit haptic bridge patch

This patch is generated from the preserved tablet checkpoint. It contains only the
DroidConverge-specific change between `feedback.cpp.before-tcp` and `feedback.cpp`.

Upstream project: Maliit
Purpose: send keyboard haptic events to the local DroidConverge Android Bridge.
The actual upstream Maliit source tree and build artifacts are intentionally not
vendored in this repository.
'@ | Set-Content -Path (Join-Path $Repo 'patches\maliit\README.md') -Encoding utf8

Write-Section 'INSTALL SCRIPTS'

@'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TERMUX_HOME="${HOME}"

install_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  chmod +x "$dst" 2>/dev/null || true
}

install_file "$ROOT/scripts/termux/anland-bridge.sh" "$TERMUX_HOME/anland-bridge.sh"
install_file "$ROOT/scripts/termux/anland-haptic-test" "$TERMUX_HOME/anland-haptic-test"
install_file "$ROOT/scripts/termux/start-ubuntu-kde.sh" "$TERMUX_HOME/start-ubuntu-kde.sh"
install_file "$ROOT/scripts/termux/startplasma-anland.sh" "$TERMUX_HOME/startplasma-anland.sh"
install_file "$ROOT/scripts/termux/.shortcuts/tasks/Ubuntu-KDE" "$TERMUX_HOME/.shortcuts/tasks/Ubuntu-KDE"
install_file "$ROOT/scripts/termux/.termux/tasker/haptic" "$TERMUX_HOME/.termux/tasker/haptic"

mkdir -p "$TERMUX_HOME/.shortcuts/tasks" "$TERMUX_HOME/.termux/tasker"
chmod +x "$TERMUX_HOME"/anland-bridge.sh "$TERMUX_HOME"/anland-haptic-test "$TERMUX_HOME"/start-ubuntu-kde.sh "$TERMUX_HOME"/startplasma-anland.sh "$TERMUX_HOME/.shortcuts/tasks/Ubuntu-KDE" "$TERMUX_HOME/.termux/tasker/haptic"

echo "DroidConverge Termux integration installed."
echo "Start KDE with: $TERMUX_HOME/start-ubuntu-kde.sh"
'@ | Set-Content -Path (Join-Path $Repo 'scripts\install\install-termux.sh') -Encoding utf8

@'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_HOME="${HOME}"
LOCAL_BIN="$TARGET_HOME/.local/bin"
CONFIG_DIR="$TARGET_HOME/.config"

mkdir -p "$LOCAL_BIN" "$CONFIG_DIR"

for f in "$ROOT"/scripts/ubuntu/*.sh "$ROOT"/scripts/ubuntu/*.py; do
  [ -f "$f" ] || continue
  cp -f "$f" "$TARGET_HOME/$(basename "$f")"
  chmod +x "$TARGET_HOME/$(basename "$f")" 2>/dev/null || true
done

for f in "$ROOT"/scripts/ubuntu/bin/*; do
  [ -f "$f" ] || continue
  cp -f "$f" "$LOCAL_BIN/$(basename "$f")"
  chmod +x "$LOCAL_BIN/$(basename "$f")"
done

# Install the example only; never create a real token-bearing config automatically.
cp -f "$ROOT/configs/droidconverge.json.example" "$CONFIG_DIR/droidconverge.json.example"

case ":${PATH}:" in
  *":$LOCAL_BIN:"*) ;;
  *) echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$TARGET_HOME/.profile" ;;
esac

echo "DroidConverge Ubuntu/KDE integration installed."
echo "Example bridge config: $CONFIG_DIR/droidconverge.json.example"
echo "Do NOT commit or copy a real token into the repository."
'@ | Set-Content -Path (Join-Path $Repo 'scripts\install\install-ubuntu.sh') -Encoding utf8

@'
param(
    [string]$AdbPath = 'C:\Users\Ciro\Desktop\platform-tools\adb.exe',
    [switch]$InstallApk
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Project = Join-Path $Root 'DroidConvergeBridge'
$Gradle = Join-Path $Project 'gradlew.bat'

if (-not (Test-Path $Gradle)) { throw "Gradle wrapper not found: $Gradle" }
if (-not (Test-Path $AdbPath)) { throw "ADB not found: $AdbPath" }

Push-Location $Project
try {
    & $Gradle clean test assembleDebug
    if ($LASTEXITCODE -ne 0) { throw "Gradle build/test failed." }
} finally {
    Pop-Location
}

$Apk = Join-Path $Project 'app\build\outputs\apk\debug\app-debug.apk'
if (-not (Test-Path $Apk)) { throw "APK not found after build: $Apk" }

Write-Host "APK: $Apk" -ForegroundColor Green

if ($InstallApk) {
    & $AdbPath devices
    if ($LASTEXITCODE -ne 0) { throw "ADB failed." }
    & $AdbPath install -r $Apk
    if ($LASTEXITCODE -ne 0) { throw "APK installation failed." }
    Write-Host 'DroidConverge Bridge installed on the connected Android device.' -ForegroundColor Green
}
'@ | Set-Content -Path (Join-Path $Repo 'scripts\install\install-android-bridge.ps1') -Encoding utf8

@'
# DroidConverge 0.3.0-dev release

This release consolidates the Android Bridge proof of concept and the preserved
Termux/Ubuntu integration from the 2026-09-15 tablet checkpoint.

Included:
- Android Bridge TCP service on `127.0.0.1:8765` with persistent authentication token.
- `ping`, `haptic`, `vibrate`, `battery`, `wifi`, `bluetooth`, and `notify` actions.
- Termux startup/Anland integration scripts.
- Ubuntu/KDE/Plasma mode scripts.
- Maliit DroidConverge haptic TCP patch.
- Sanitized example configuration without a real token.
- Reproducible Android, Termux and Ubuntu installation helpers.

Not included:
- Raw checkpoint archives.
- Upstream Maliit/Plasma Mobile source trees.
- Build directories and locally generated binaries.
- Real bridge tokens or personal configuration.

Known limitation:
`durationMs` is intentionally not part of the Bridge protocol yet. The existing
settings UI may contain duration fields, but the TCP request does not expose or
consume a duration parameter in this release.

Security:
The bridge is intended for rooted personal devices and binds to loopback only.
Protect the authentication token and never commit a real `droidconverge.json`.

This is a development/prerelease checkpoint rather than a Play Store production
release. Distribution outside the repository should use a properly signed APK.
'@ | Set-Content -Path (Join-Path $Repo 'docs\RELEASE-0.3.0.md') -Encoding utf8

@'
## DroidConverge 0.3.0-dev â€” checkpoint release

The repository now contains the preserved Android Bridge, Termux startup integration,
Ubuntu/KDE/Anland helper scripts and the DroidConverge-specific Maliit patch recovered
from the 2026-09-15 tablet checkpoint. Raw checkpoint archives, upstream source trees,
build artifacts and real tokens remain outside the repository.

### Quick installation

Android Bridge (Windows/PC):

```powershell
.\scripts\install\install-android-bridge.ps1 -InstallApk
```

Termux:

```bash
bash ~/path/to/droidconverge/scripts/install/install-termux.sh
```

Ubuntu/KDE:

```bash
bash ~/path/to/droidconverge/scripts/install/install-ubuntu.sh
```

After launching the Android Bridge, copy the generated token into your local
`~/.config/droidconverge.json`. Never put that real token in Git.

### Security and scope

DroidConverge is designed for rooted/personal Android + Linux convergence setups.
The Android Bridge listens on `127.0.0.1` and authenticates requests with a persistent
token. Root-only device toggles such as Wi-Fi/Bluetooth are intentionally privileged.
Do not expose the bridge port outside the local device and do not share the real token.

### Current release limitation

`durationMs` is not implemented in the Bridge protocol yet. The presence of duration
fields in the Android settings UI does not mean callers can request an arbitrary
request duration in this release.

See `docs/RELEASE-0.3.0.md` for the complete release scope and `docs/INSTALLATION.md`
for the broader project installation documentation.
'@ | Add-Content -Path (Join-Path $Repo 'README.md') -Encoding utf8

@'

## 0.3.0-dev checkpoint installation

### Android Bridge

From the repository root on Windows:

```powershell
.\scripts\install\install-android-bridge.ps1 -InstallApk
```

The script runs the Gradle tests and builds `app-debug.apk`, then installs it with
ADB when `-InstallApk` is supplied. For release distribution, use a properly signed
APK rather than the debug build.

### Termux integration

Run `scripts/install/install-termux.sh` from a Termux shell after the repository is
available locally on the device. It installs the preserved Anland/KDE launcher,
startup and haptic helper scripts plus the `.shortcuts` and Tasker entry points.

### Ubuntu/KDE integration

Run `scripts/install/install-ubuntu.sh` inside the Ubuntu environment. It installs
the preserved Plasma mode helpers and the sanitized bridge configuration example.
The real bridge token is generated by the Android app and must remain local.

### Maliit

The repository contains a small DroidConverge-specific patch under
`patches/maliit/`. The upstream Maliit source is not vendored; apply the patch to
the matching upstream source tree before building `maliit-keyboard`.
'@ | Add-Content -Path (Join-Path $Repo 'docs\INSTALLATION.md') -Encoding utf8

@'
# DroidConverge release packaging ignores
checkpoint-recovery/
release-artifacts/
*.apk
*.aab
*.apks
DroidConvergeBridge/local.properties
DroidConvergeBridge/.gradle/
DroidConvergeBridge/**/build/
'@ | Add-Content -Path (Join-Path $Repo '.gitignore') -Encoding utf8

Write-Section 'VERSION / CHANGELOG'
$changelog = Join-Path $Repo 'CHANGELOG.md'
$existing = if (Test-Path $changelog) { Get-Content -Raw -LiteralPath $changelog } else { '' }
if ($existing -notmatch '## 0\.3\.0-dev') {
    @'
## 0.3.0-dev - 2026-09-15

- Consolidated the Android Bridge TCP service and authentication model.
- Recovered and packaged the Termux/Ubuntu startup integration from the tablet checkpoint.
- Added DroidConverge-specific Maliit haptic TCP patch packaging.
- Added Android, Termux and Ubuntu installation helpers.
- Added release/security documentation and sanitized configuration example.
- Explicitly kept `durationMs` out of the protocol for this checkpoint.

'@ + $existing | Set-Content -LiteralPath $changelog -Encoding utf8
}

Write-Section 'CLEANUP'
# Recovery material is source-of-truth input, not repository content.
if (Test-Path $Checkpoint) { Remove-Item -Recurse -Force $Checkpoint }
# Remove known temporary local scripts from earlier iterations if still present.
foreach ($tmp in @('apply_fix.ps1','update_droidconverge_bridge_v0_3.ps1')) {
    $p = Join-Path $Repo $tmp
    if (Test-Path $p) { Remove-Item -Force $p }
}

Write-Section 'VERIFY / BUILD'
& git diff --check
if ($LASTEXITCODE -ne 0) { throw 'git diff --check failed.' }

Push-Location $Android
try {
    & .\gradlew.bat clean test assembleDebug
    if ($LASTEXITCODE -ne 0) { throw 'Android Bridge Gradle verification failed.' }
} finally {
    Pop-Location
}

$apk = Join-Path $Android 'app\build\outputs\apk\debug\app-debug.apk'
if (-not (Test-Path $apk)) { throw "Expected APK not found: $apk" }

Write-Section 'GIT COMMIT / PUSH'
git add -A
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged diff check failed.' }

git commit -m 'release: consolidate DroidConverge 0.3.0-dev checkpoint'
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }

git push origin main
if ($LASTEXITCODE -ne 0) { throw 'Git push failed.' }

$tag = 'v0.3.0-dev'
if (-not (git tag --list $tag)) {
    git tag -a $tag -m 'DroidConverge 0.3.0-dev'
    git push origin $tag
}

Write-Section 'RELEASE'
Write-Host "APK ready: $apk" -ForegroundColor Green
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        gh release create $tag $apk --title 'DroidConverge 0.3.0-dev' --notes-file (Join-Path $Repo 'docs\RELEASE-0.3.0.md') --prerelease
        Write-Host 'GitHub prerelease created with gh.' -ForegroundColor Green
    } catch {
        Write-Warning 'gh exists but release creation failed; the commit/tag were still pushed.'
    }
} else {
    Write-Host 'GitHub CLI (gh) not found; commit and tag are already pushed.' -ForegroundColor Yellow
    Write-Host "Create the GitHub prerelease manually and attach: $apk"
}

Write-Section 'DONE'
Write-Host 'DroidConverge 0.3.0-dev checkpoint finalization completed.' -ForegroundColor Green

