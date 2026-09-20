param(
    [string]$AdbPath = "adb",
    [string]$DeviceSerial,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "../..")
$project = Join-Path $repo "DroidConvergeBridge"

if (-not (Test-Path $project)) { throw "DroidConvergeBridge project not found: $project" }

if (-not $SkipBuild) {
    Push-Location $project
    try {
        & .\gradlew.bat assembleDebug
        if ($LASTEXITCODE -ne 0) { throw "Gradle build failed" }
    } finally { Pop-Location }
}

$apk = Join-Path $project "app/build/outputs/apk/debug/app-debug.apk"
if (-not (Test-Path $apk)) { throw "APK not found: $apk" }

Write-Host "Installing $apk"
$adbArgs = @()
if ($DeviceSerial) { $adbArgs += @("-s", $DeviceSerial) }
& $AdbPath @adbArgs install -r $apk
if ($LASTEXITCODE -ne 0) { throw "adb install failed" }

Write-Host "Android Bridge installation completed."
