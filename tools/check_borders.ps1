



# read-only: list every window titled AHKWM_BORDER (the WM's border frames)
# use: powershell -NoProfile -File tools\check_borders.ps1
# each listed frame should hug one real window; a row matching no window is a leaked frame
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class B {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@

$rows = New-Object System.Collections.Generic.List[object]
$cb = [B+EnumProc]{
  param($h, $l)
  $t = New-Object Text.StringBuilder 256
  [B]::GetWindowTextW($h, $t, 256) | Out-Null
  if ($t.ToString() -eq 'AHKWM_BORDER') {
    $cn = New-Object Text.StringBuilder 256
    [B]::GetClassName($h, $cn, 256) | Out-Null
    $p = 0
    [B]::GetWindowThreadProcessId($h, [ref]$p) | Out-Null
    $r = New-Object B+RECT
    [B]::GetWindowRect($h, [ref]$r) | Out-Null
    $rows.Add([pscustomobject]@{
      Hwnd = ('0x{0:X}' -f [int64]$h); Pid = $p; Class = $cn.ToString()
      Vis  = [B]::IsWindowVisible($h)
      L = $r.L; T = $r.T; W = ($r.R - $r.L); H = ($r.B - $r.T)
    })
  }
  return $true
}
[B]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null

Write-Host ("total border windows: " + $rows.Count)
$rows | Sort-Object Pid, L, T | Format-Table -AutoSize | Out-String -Width 200
