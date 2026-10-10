#!/usr/bin/env bash
# 单一版本源：wm.ahk 里的 global WM_Version 是唯一权威，其他文档的版本号由本脚本注入。
# CHANGELOG 不在同步范围内 —— 每个条目是属于它自己那个版本的，改版本号就篡改历史了。
#
#   bash docs/tools/sync_version.sh            # 按 wm.ahk 改写 4 个文档里的版本号
#   bash docs/tools/sync_version.sh --check     # 只检查是否漂移，不写文件（CI 用）
set -euo pipefail
cd "$(dirname "$0")/../.."

CHECK=0
case "${1:-}" in
    "")          ;;
    --check|-c)  CHECK=1 ;;
    *)           echo "用法: $0 [--check]" >&2; exit 2 ;;
esac

V=$(grep -m1 '^global WM_Version :=' wm.ahk | sed -E 's/.*"([^"]+)".*/\1/')
if ! [[ $V =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "sync_version: 无法从 wm.ahk 读出 WM_Version（读到 '$V'）" >&2
    exit 1
fi

# 每个文件一组 perl 替换规则，只碰版本号出现的那几处，绝不碰其它文本。
rules_for() {
    case "$1" in
        README.md|docs/README-zh.md)
            # 标题 <sub>vX.Y.Z</sub> 与 shields.io 徽章 badge/version-vX.Y.Z、badge/版本-vX.Y.Z
            printf '%s' \
                's|<sub>v[0-9][0-9.]*</sub>|<sub>v'"$V"'</sub>|;'\
                's|(badge/version-)v[0-9][0-9.]*|${1}v'"$V"'|;'\
                's|(badge/版本-)v[0-9][0-9.]*|${1}v'"$V"'|'
            ;;
        docs/config-reference.md)
            printf '%s' 's|^(# AHK_WM Configuration Reference \()v[0-9][0-9.]*(\))|${1}v'"$V"'${2}|'
            ;;
        docs/config-reference-zh.md)
            printf '%s' 's|^(# AHK_WM 配置参考（v)[0-9][0-9.]*|${1}'"$V"'|'
            ;;
        *)
            echo "sync_version: 没有为 $1 定义规则" >&2
            exit 1
            ;;
    esac
}

FILES=(README.md docs/README-zh.md docs/config-reference.md docs/config-reference-zh.md)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

drift=0
for f in "${FILES[@]}"; do
    perl -pe "$(rules_for "$f")" "$f" > "$tmp/$(basename "$f")"
    if cmp -s "$f" "$tmp/$(basename "$f")"; then
        printf '  = %s\n' "$f"
        continue
    fi
    drift=1
    if (( CHECK )); then
        printf '  ! %s 版本号未同步:\n' "$f"
        diff -u "$f" "$tmp/$(basename "$f")" | sed -n '3,12p' | sed 's/^/      /' || true
    else
        cp "$tmp/$(basename "$f")" "$f"
        printf '  * %s -> v%s\n' "$f" "$V"
    fi
done

if (( CHECK )); then
    if (( drift )); then
        echo "sync_version: 文档版本号与 wm.ahk 的 v$V 不一致（跑 $0 修复）" >&2
        exit 1
    fi
    echo "sync_version: 4 个文档版本号均为 v$V"
else
    echo "sync_version: 已同步到 v$V（wm.ahk 为权威源）"
fi
