# 只读探针：列出某个进程拥有的所有顶层窗口（类别 / 可见性 / 位置 / 置顶位）
# 用法: powershell -NoProfile -File tools\probe_wins.ps1 -Pid 7452
param([Parameter(Mandatory=$true)][int]$TargetPid)

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtr(IntPtr h, int i);
  [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint c);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@

$rows = New-Object System.Collections.Generic.List[object]
$cb = [W+EnumProc]{
  param($h, $l)
  $p = 0
  [W]::GetWindowThreadProcessId($h, [ref]$p) | Out-Null
  if ($p -eq $TargetPid) {
    $cn = New-Object Text.StringBuilder 256
    [W]::GetClassName($h, $cn, 256) | Out-Null
    $tt = New-Object Text.StringBuilder 256
    [W]::GetWindowTextW($h, $tt, 256) | Out-Null
    $r = New-Object W+RECT
    [W]::GetWindowRect($h, [ref]$r) | Out-Null
    $ex = [int64][W]::GetWindowLongPtr($h, -20)
    $prev = [W]::GetWindow($h, 3)          # GW_HWNDPREV
    $rows.Add([pscustomobject]@{
      Hwnd    = ('0x{0:X}' -f [int64]$h)
      Class   = $cn.ToString()
      Vis     = [W]::IsWindowVisible($h)
      Topmost = [bool]($ex -band 0x8)
      Layered = [bool]($ex -band 0x80000)
      L = $r.L; T = $r.T; W = ($r.R - $r.L); H = ($r.B - $r.T)
      Below   = ('0x{0:X}' -f [int64]$prev)
      Title   = $tt.ToString()
    })
  }
  return $true
}
[W]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null

$out = $rows | Sort-Object L, T | Format-Table -AutoSize | Out-String -Width 200
Write-Host $out
Set-Content -Path ($PSScriptRoot + '\probe_wins.out.txt') -Value $out -Encoding UTF8
