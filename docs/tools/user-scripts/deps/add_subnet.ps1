# Auto-add a subnet IP to local machine so devices on other subnets can be pinged.
# Usage: powershell -File add_subnet.ps1 -ip 10.252.156.1 -mask 255.255.0.0 -gw 10.252.0.1
#   -mask / -gw optional: device's real mask/gateway from discovery. Use them when present.
#   Without them, defaults to /24 with an auto-picked host IP.
#   New IP = highest host in subnet (broadcast-1), stepping down past device IP and gateway.
# Exit codes: 0=already exists/added, 1=bad arg/no room, 2=no interface, 3=add failed (needs admin)
param([string]$ip, [string]$mask, [string]$gw)
$ErrorActionPreference = 'Continue'

if (-not $ip) { exit 1 }
$ipParts = $ip -split '\.'
if ($ipParts.Count -ne 4) { exit 1 }

# Default mask /24 if not given or malformed
if (-not $mask -or $mask -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { $mask = '255.255.255.0' }
$maskParts = $mask -split '\.'

# IPv4 dotted-quad -> [long] (0..4294967295)
function To-Long([string[]]$parts) {
    $r = [long]0
    foreach ($p in $parts) { $r = ($r -shl 8) -bor [long]([int]$p) }
    return $r
}

$ipL   = To-Long $ipParts
$maskL = To-Long $maskParts

# Prefix length = number of 1 bits in mask (valid netmasks are contiguous)
$prefix = 0
for ($i = 0; $i -lt 32; $i++) { $prefix += [int](($maskL -shr $i) -band 1) }
if ($prefix -lt 1 -or $prefix -ge 32) { $prefix = 24 }

$netL   = $ipL -band $maskL
$bcastL = $netL -bor ($maskL -bxor 0xFFFFFFFFL)

# Already have an IP in this exact subnet? (compare network, not just first octets)
$existing = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
    $_.IPAddress -match '^\d{1,3}(\.\d{1,3}){3}$' -and
    ((To-Long ($_.IPAddress -split '\.')) -band $maskL) -eq $netL
}
if ($existing) { exit 0 }

# Pick a free host IP: highest host (broadcast-1), stepping down past device IP and gateway
$avoid = @($ipL)
if ($gw -and $gw -match '^\d{1,3}(\.\d{1,3}){3}$') {
    $avoid += (To-Long ($gw -split '\.'))
}
$cand = $bcastL - 1
for ($tries = 0; $tries -lt 20 -and ($avoid -contains $cand); $tries++) { $cand-- }
if ($cand -le $netL -or $cand -ge $bcastL) { exit 1 }

$newip = '{0}.{1}.{2}.{3}' -f `
    ([int](($cand -shr 24) -band 0xFF)), ([int](($cand -shr 16) -band 0xFF)), `
    ([int](($cand -shr 8)  -band 0xFF)), ([int]($cand -band 0xFF))

# Target adapter = "以太网2" (Intel I219-V). Match by description to avoid Chinese-encoding issues.
$adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*I219-V*" -and $_.Status -eq 'Up' } | Select-Object -First 1
if (-not $adapter) {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
}
if (-not $adapter) { exit 2 }

New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $newip -PrefixLength $prefix -ErrorAction SilentlyContinue | Out-Null

if (-not (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -eq $newip })) {
    exit 3
}
exit 0
