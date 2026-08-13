# Packages the addon for distribution.
#
# Two things this has to get right. The zip must contain a single top-level
# folder whose name matches the .toc file, because that is how WoW finds an
# addon — extracting a bare pile of files into Interface\AddOns installs
# nothing. And the development-only files stay out: Ports/ holds type contracts
# the language server reads at edit time, and nothing in the .toc loads them.

$ErrorActionPreference = "Stop"

$AddonName = "AuraTrackerQuestor"
$Root = $PSScriptRoot
$Output = Join-Path $Root "dist"
$Staging = Join-Path $Output $AddonName

# Everything the game actually loads, and nothing else.
$Runtime = @(
    "$AddonName.toc",
    "Bindings.xml",
    "Bootstrap.lua",
    "Libs",
    "Locales",
    "Core",
    "Game",
    "System",
    "Modules",
    "UI",
    "Options"
)

$tocPath = Join-Path $Root "$AddonName.toc"
$versionLine = Select-String -Path $tocPath -Pattern "^## Version:\s*(.+)$"
if (-not $versionLine) { throw "Version not found in $AddonName.toc" }
$Version = $versionLine.Matches[0].Groups[1].Value.Trim()

if (Test-Path $Output) { Remove-Item $Output -Recurse -Force }
New-Item -ItemType Directory -Path $Staging -Force | Out-Null

foreach ($item in $Runtime) {
    $source = Join-Path $Root $item
    if (-not (Test-Path $source)) { throw "Missing: $item" }
    Copy-Item $source -Destination $Staging -Recurse
}

# A file listed in the .toc but absent from the package fails at load time, in
# the player's client, with no clue why. Cheaper to catch it here.
$listed = Get-Content $tocPath | Where-Object { $_ -match "\.lua$" } | ForEach-Object { $_.Trim() }
foreach ($file in $listed) {
    if (-not (Test-Path (Join-Path $Staging $file))) { throw "In .toc but not packaged: $file" }
}

# And the other way round: a file written but never registered simply never
# loads, which looks like the feature was never written.
$listedSet = @{}
foreach ($file in $listed) { $listedSet[$file] = $true }

foreach ($file in Get-ChildItem $Staging -Recurse -File -Filter *.lua) {
    $relative = $file.FullName.Substring($Staging.Length + 1)
    if (-not $listedSet.ContainsKey($relative)) { throw "Packaged but not in .toc: $relative" }
}

$Archive = Join-Path $Output "$AddonName-$Version.zip"
Compress-Archive -Path $Staging -DestinationPath $Archive -Force

"$AddonName $Version"
"  $((Get-ChildItem $Staging -Recurse -File).Count) arquivos"
"  $Archive"
