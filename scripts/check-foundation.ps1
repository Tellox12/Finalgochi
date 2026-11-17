$ErrorActionPreference = "Stop"

$swiftRoot = Join-Path $env:LOCALAPPDATA "Programs\Swift"
$toolchainsPath = Join-Path $swiftRoot "Toolchains"
$toolchain = Get-ChildItem $toolchainsPath -Directory |
    Sort-Object { [version]($_.Name -replace '\+.*$', '') } -Descending |
    Select-Object -First 1

if (-not $toolchain) {
    throw "No encontré un toolchain de Swift en $toolchainsPath. Instala Swift y abre una terminal nueva."
}

$swiftc = Join-Path $toolchain.FullName "usr\bin\swiftc.exe"
$swiftVersion = $toolchain.Name -replace '\+.*$', ''
$sdk = Join-Path $swiftRoot "Platforms\$swiftVersion\Windows.platform\Developer\SDKs\Windows.sdk"

if (-not (Test-Path $swiftc)) {
    throw "No encontré swiftc en $swiftc. Revisa la instalación de Swift."
}

if (-not (Test-Path $sdk)) {
    throw "No encontré el SDK de Windows de Swift en $sdk. Reinstala Swift desde Swift.org/WinGet."
}

if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    $target = "aarch64-unknown-windows-msvc"
} else {
    $target = "x86_64-unknown-windows-msvc"
}

& $swiftc -sdk $sdk -target $target -swift-version 5 -typecheck `
    .\Models\PetModel.swift `
    .\Models\StoreItem.swift `
    .\Models\WorldPhase.swift `
    .\Models\DailyQuest.swift `
    .\Managers\GameManager.swift

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Swift Foundation check passed for $target."
