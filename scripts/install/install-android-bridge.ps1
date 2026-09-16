$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Gradle = Join-Path $Root "DroidConvergeBridge\gradlew.bat"
$Apk = Join-Path $Root "DroidConvergeBridge\app\build\outputs\apk\debug\app-debug.apk"
$Adb = if ($env:ADB) { $env:ADB } else { "adb" }

Push-Location (Join-Path $Root "DroidConvergeBridge")
try {
    & $Gradle clean assembleDebug
    if ($LASTEXITCODE -ne 0) {
        throw "Gradle build fallito."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path $Apk)) {
    throw "APK non trovato: $Apk"
}

& $Adb install -r $Apk
if ($LASTEXITCODE -ne 0) {
    throw "Installazione ADB fallita."
}

Write-Host "Android Bridge installato: $Apk" -ForegroundColor Green
