#!/usr/bin/env bash
# AHK v2 语法检查（不执行脚本）
# 用法: bash docs/tools/validate.sh [脚本路径...]   默认检查 wm.ahk
# 退出码: 0 = 语法通过, 2 = 有语法错误（错误信息已打印）
set -uo pipefail

AHK='C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
TMP="${TEMP:-/c/Users/Administrator/AppData/Local/Temp}/ahkcheck"
mkdir -p "$TMP" 2>/dev/null

rc=0
for f in "${@:-wm.ahk}"; do
    # 转成 Windows 绝对路径
    win=$(cd "$(dirname "$f")" && pwd -W)/$(basename "$f")
    err="$TMP/$(basename "$f").err"
    rm -f "$err"
    msys2_arg_conv=0 powershell -NoProfile -Command \
        "\$p = Start-Process -FilePath '$AHK' -ArgumentList '/validate','/ErrorStdOut','$(echo "$win" | sed 's|/|\\|g')' -Wait -PassThru -NoNewWindow -RedirectStandardError '$(echo "$err" | sed 's|/|\\|g')'; exit \$p.ExitCode" 2>/dev/null
    code=$?
    if [ "$code" -eq 0 ]; then
        echo "OK    $f"
    else
        echo "FAIL  $f (exit=$code)"
        cat "$err" 2>/dev/null
        rc=$code
    fi
done
exit $rc
