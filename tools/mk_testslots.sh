#!/usr/bin/env bash
# 从 wm.ahk 原样抽取纯函数，拼出可独立运行的测试脚本 tools/test_slots.ahk
set -euo pipefail
cd "$(dirname "$0")/.."

extract() {   # $1 = 顶层函数名（匹配行首 "name(" 到行首 "}"）
    awk -v f="$1" 'index($0, f "(") == 1 {on=1} on {print} on && $0 == "}" {exit}' wm.ahk
}

{
    echo '#Requires AutoHotkey v2.0'
    echo '#SingleInstance Off'
    echo '; ==== 由 tools/mk_testslots.sh 从 wm.ahk 自动抽取，请勿手工编辑 ===='
    echo ''
    echo '; ---- 桩函数 ----'
    echo 'WMLog(msg) {'
    echo '    return'
    echo '}'
    for f in ParseAxis ParseLayoutRules GetCustomLayout SlotFromSpan PickSlotFromTable \
             NarrowByAxis _GetTileMode ComputeTileRect MoveWinTo EmitPlace TileGrid \
             TileNormal TileVertical TileUltrawide BuildBuiltinSlotTable; do
        echo ''
        echo "; ---- 抽取自 wm.ahk: $f ----"
        extract "$f"
    done
    cat tools/test_slots_body.ahk
} > tools/test_slots.ahk

echo "已生成 tools/test_slots.ahk ($(wc -l < tools/test_slots.ahk) 行)"
