# 在 UTF-16LE+BOM 的 ini 里"新增"一个键（不改动任何既有行）
# 用法: powershell -NoProfile -File tools\cfg_set_key.ps1 -Anchor AnimationDuration -Key WTMDebug -Value on
param(
    [string]$Path   = 'C:\Users\Administrator\.config\AHK_WM\wm_config.ini',
    [Parameter(Mandatory=$true)][string]$Anchor,
    [Parameter(Mandatory=$true)][string]$Key,
    [Parameter(Mandatory=$true)][string]$Value
)

$enc   = New-Object System.Text.UnicodeEncoding($false, $true)   # LE + BOM
$bytes = [IO.File]::ReadAllBytes($Path)
$text  = $enc.GetString($bytes)
if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }

$nl    = "`r`n"
$lines = $text -split $nl

foreach ($l in $lines) {
    if ($l -match ("^" + [regex]::Escape($Key) + "=")) { Write-Host "ALREADY-EXISTS"; exit 2 }
}

$out  = New-Object System.Collections.Generic.List[string]
$done = $false
foreach ($l in $lines) {
    $out.Add($l)
    if (-not $done -and $l -match ("^" + [regex]::Escape($Anchor) + "=")) {
        $out.Add("$Key=$Value")
        $done = $true
    }
}
if (-not $done) { Write-Host "ANCHOR-NOT-FOUND: $Anchor"; exit 3 }

[IO.File]::WriteAllText($Path, ($out -join $nl), $enc)
Write-Host "OK  added $Key=$Value after $Anchor"
exit 0
