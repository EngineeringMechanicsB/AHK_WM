#!/usr/bin/env bash
# 从 wm.ahk 原样抽取纯函数，拼出可独立运行的测试脚本 docs/tools/test_slots.ahk
set -euo pipefail
cd "$(dirname "$0")/../.."

extract() {   # $1 = 顶层函数名（匹配行首 "name(" 到行首 "}"）
    awk -v f="$1" 'index($0, f "(") == 1 {on=1} on {print} on && $0 == "}" {exit}' wm.ahk
}

{
    printf '\xEF\xBB\xBF'   # UTF-8 BOM：否则 AHK 按 ANSI 读，中文串会吞掉引号
    echo '#Requires AutoHotkey v2.0'
    echo '#SingleInstance Off'
    echo '; ==== 由 tools/mk_testslots.sh 从 wm.ahk 自动抽取，请勿手工编辑 ===='
    echo ''
    echo '; ---- 桩函数 ----'
    echo 'WMLog(msg) {'
    echo '    return'
    echo '}'
    echo '; 测试台里没有真实显示器：MonitorGetWorkArea 返回固定工作区，'
    echo '; 由测试主体按需改写（BuildLayoutRulesForMonitor 只依赖 GetTileArea 的取区口径）。'
    echo 'TestWorkArea := {l: 0, t: 0, r: 1920, b: 1080}'
    echo 'MonitorGetWorkArea(idx, &L, &T, &R, &B) {'
    echo '    global TestWorkArea'
    echo '    L := TestWorkArea.l, T := TestWorkArea.t'
    echo '    R := TestWorkArea.r, B := TestWorkArea.b'
    echo '}'
    echo 'BarReserve(monIdx, &L, &T, &R, &B) {'
    echo '    return'
    echo '}'
    for f in ParseAxis ParseLayoutRules GetCustomLayout SlotFromSpan SlotIndexAtPoint \
             RectBBox SortRowsByX SlotAssign PickSlotFromTable \
             NarrowByAxis NarrowByBand ResizeSpans QuantizeSpans RuleStringFor LayoutAxisToken \
             _GetTileMode ComputeTileRect MoveWinTo EmitPlace TileGrid \
             TileNormal TileVertical TileUltrawide BuildBuiltinSlotTable \
             GetTileArea SortRectsForRules BuildLayoutRulesForMonitor \
             GlobMatch _StripExe MatchField MatchTitleRule ExclFieldBit \
             SplitExcludeList ExclParseSection ExclRecomputeNeed \
             ExclFileHeader ExclPresetIni EnsureExcludeFile ExclReadSection \
             LoadExcludeRules ExclRuleExists PauseModeRead ExclRefreshPreset; do
        echo ''
        echo "; ---- 抽取自 wm.ahk: $f ----"
        extract "$f"
    done
    # ExclPresetIniText 是顶层 global（多行拼接），单独抽
    echo ''
    echo '; ---- 抽取自 wm.ahk: global ExclPresetIniText ----'
    awk '
        /^global ExclPresetIniText := ""/ { on = 1 }
        on {
            if ($0 !~ /^global ExclPresetIniText/ && $0 !~ /^[ \t]*\. "/) exit
            print
        }
    ' wm.ahk
    echo ''
    echo '; ---- 抽取自 wm.ahk: global ExclPresetRev ----'
    grep '^global ExclPresetRev' wm.ahk
    cat docs/tools/test_slots_body.ahk
} > docs/tools/test_slots.ahk

echo "已生成 docs/tools/test_slots.ahk ($(wc -l < docs/tools/test_slots.ahk) 行)"
