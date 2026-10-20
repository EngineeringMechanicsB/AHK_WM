<#
  sync-drives.ps1 —— 「此电脑」替代目录自动同步

  作用:  把系统里当前所有可用盘符映射成 C:\Users\Administrator\drives\ 下的 junction,
         命名规则 <盘符>-<卷标>, 例: C-系统  D-本地磁盘  F-Ventoy
         插拔 U 盘/移动硬盘、卷标改名 → yazi 的 g p 列表自动跟着变

  调用:  powershell -NoProfile -ExecutionPolicy Bypass -File sync-drives.ps1
         (GuiPing.ahk 在 Win+E 前调用一次; 盘符变化时后台再调用一次)

  安全:  只增删改 junction(重解析点);
         删除走 [IO.Directory]::Delete(path, $false), 只摘链接, 绝不递归进目标盘;
         任何普通文件/目录一律不动。
  回退:  rmdir "C:\Users\Administrator\drives"   (整目录删掉也只是删链接, 不动盘里数据)
#>

$ErrorActionPreference = 'Stop'

$base   = 'C:\Users\Administrator\drives'
$logDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$log    = Join-Path $logDir 'sync-drives.log'

$changes = New-Object System.Collections.Generic.List[string]

function Write-Log([string]$msg) {
    $null = $changes.Add("  $msg")
}

function Get-TypeName([string]$t) {
    switch ($t) {
        'Fixed'     { return '本地磁盘' }
        'Removable' { return '可移动磁盘' }
        'Network'   { return '网络驱动器' }
        'CDRom'     { return '光驱' }
        default     { return '磁盘' }
    }
}

# <盘符>-<卷标>, 卷标为空/等于盘符本身时回退到类型名
function Get-DriveName([string]$letter, [string]$label, [string]$type) {
    $l = "$label".Trim()
    $l = ($l -replace '[\\/:*?"<>|]', '').Trim()
    if ($l.Length -gt 20) { $l = $l.Substring(0, 20).Trim() }
    if ($l -eq '' -or $l.ToUpper() -eq $letter.ToUpper()) { $l = Get-TypeName $type }
    return "$letter-$l"
}

# junction 的目标, 归一成 "C:\" 这种形式; 取不到返回 $null
function Get-NormTarget($item) {
    $t = $null
    try { $t = $item.Target } catch { }
    if (-not $t) { try { $t = $item.LinkTarget } catch { } }
    if ($null -eq $t) { return $null }
    if ($t -is [array]) { $t = $t[0] }
    $s = "$t"
    if ($s -match '^([A-Za-z]):\\?$') { return ($Matches[1].ToUpper() + ':\') }
    return $s.TrimEnd('\')
}

# 是不是重解析点(链接)。普通文件/目录一律不动。
function Test-IsLink($item) {
    return [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
}

# 只摘链接。Directory.Delete(recursive=$false) 对 junction 只删重解析点, 不递归。
function Remove-Link([string]$path) {
    try {
        [System.IO.Directory]::Delete($path, $false)
    } catch {
        & cmd.exe /c rmdir "$path" | Out-Null
    }
}

try {
    if (-not (Test-Path -LiteralPath $base)) {
        New-Item -ItemType Directory -Path $base -Force | Out-Null
    }

    # ---- 1. 当前系统里可用的卷 ----
    $vols = @{}
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        try {
            if (-not $d.IsReady) { continue }
            if ("$($d.Name)" -notmatch '^[A-Za-z]:\\$') { continue }   # 跳过挂载点式的卷
            $type = "$($d.DriveType)"
            if ($type -notin @('Fixed', 'Removable', 'Network', 'CDRom')) { continue }

            $letter = $d.Name.Substring(0, 1).ToUpper()
            $vols[$letter] = [pscustomobject]@{
                Letter = $letter
                Target = "$($d.Name)"
                Name   = Get-DriveName $letter $d.VolumeLabel $type
            }
        } catch { }
    }

    # ---- 2. drives 目录里现有的链接 ----
    $links = @{}
    foreach ($it in (Get-ChildItem -LiteralPath $base -Force)) {
        if (-not (Test-IsLink $it)) { continue }
        $nt = Get-NormTarget $it
        if (-not $nt) { continue }
        $links[$it.Name] = [pscustomobject]@{ Path = $it.FullName; Name = $it.Name; Target = $nt }
    }

    # ---- 3. 新增 / 按卷标改名(按 target 匹配, 不按名字) ----
    foreach ($L in ($vols.Keys | Sort-Object)) {
        $v   = $vols[$L]
        $hit = $null
        foreach ($k in $links.Keys) {
            if ($links[$k].Target -eq $v.Target) { $hit = $links[$k]; break }
        }

        if ($hit -and $hit.Name -eq $v.Name) { continue }   # 已就绪

        if ($hit) {
            try {
                Rename-Item -LiteralPath $hit.Path -NewName $v.Name -ErrorAction Stop
                Write-Log "改名: $($hit.Name)  ->  $($v.Name)"
            } catch {
                Write-Log "改名失败: $($hit.Name) -> $($v.Name) : $($_.Exception.Message)"
            }
            continue
        }

        $path = Join-Path $base $v.Name
        if (Test-Path -LiteralPath $path) {
            Write-Log "跳过(同名项已存在且不是链接): $path"
            continue
        }
        try {
            New-Item -ItemType Junction -Path $path -Target $v.Target -ErrorAction Stop | Out-Null
            Write-Log "新增: $($v.Name)  ->  $($v.Target)"
        } catch {
            Write-Log "新增失败: $($v.Name) -> $($v.Target) : $($_.Exception.Message)"
        }
    }

    # ---- 4. 清理: 目标盘符已不存在的链接 ----
    foreach ($k in @($links.Keys)) {
        $t = $links[$k].Target
        if ($t -notmatch '^([A-Za-z]):') { continue }
        $dl = $Matches[1].ToUpper()
        if ($vols.ContainsKey($dl)) { continue }
        try {
            Remove-Link $links[$k].Path
            Write-Log "清理: $k   (目标盘 ${dl}: 已不存在)"
        } catch {
            Write-Log "清理失败: $k : $($_.Exception.Message)"
        }
    }
}
catch {
    $null = $changes.Add("  ERROR: $($_.Exception.Message)")
}

if ($changes.Count -gt 0) {
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $log -Value (@("[$stamp]") + $changes) -Encoding UTF8
}

exit 0
