#!/usr/bin/env bash
# 重建并运行槽位/方向数学测试台（纯函数，不移动任何窗口）
# 用法: bash docs/tools/run_testslots.sh
# 退出码: 0 = 全部断言通过, 1 = 有断言失败, 3 = 未捕获异常, 2 = 路径/语法问题
#
# 为什么不直接手搓 PowerShell：
#   脚本自身会写 docs/tools/test_slots.out.txt，stdout/stderr 必须重定向到**别的**文件，
#   否则两个句柄抢同一路径 → FileAppend 抛 error 32 → AHK 弹错误对话框。
#   （这里固定用 test_slots.stdout.txt / .stderr.txt，都在 .gitignore 里）
set -uo pipefail

AHK='C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="$(cd "$HERE" && pwd -W)"                 # docs/tools 目录的 Windows 路径
W() { echo "$1" | sed 's|/|\\|g'; }           # 正斜杠 → 反斜杠

bash "$HERE/mk_testslots.sh" || exit 1

powershell -NoProfile -Command \
    "\$p = Start-Process -FilePath '$AHK' -ArgumentList '$(W "$DIR")\\test_slots.ahk' -Wait -PassThru -NoNewWindow -RedirectStandardOutput '$(W "$DIR")\\test_slots.stdout.txt' -RedirectStandardError '$(W "$DIR")\\test_slots.stderr.txt'; exit \$p.ExitCode" 2>/dev/null
code=$?

[ -f "$HERE/test_slots.out.txt" ] && tail -4 "$HERE/test_slots.out.txt"
[ "$code" -ne 0 ] && { echo "--- stderr ---"; cat "$HERE/test_slots.stderr.txt" 2>/dev/null; }
echo "exit=$code   明细: docs/tools/test_slots.out.txt"
exit $code
