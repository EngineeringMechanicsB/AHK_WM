#!/usr/bin/env bash
# 单一版本源：wm.ahk 里的 global WM_Version 是唯一权威，其他文档的版本号由本脚本注入。
# CHANGELOG 条目标题不会被改写（每个条目属于它自己那个版本），但 --check 会确认
# 当前版本在 CHANGELOG.md / CHANGELOG-zh.md 里各有一个 "### vX.Y.Z" 条目。
#
#   bash docs/tools/sync_version.sh                 # 按 wm.ahk 改写 4 个文档里的版本号
#   bash docs/tools/sync_version.sh --check         # 只检查：文档漂移 + CHANGELOG 条目
#   bash docs/tools/sync_version.sh --set 2.13.0    # 改 wm.ahk 的 WM_Version，再同步文档
set -euo pipefail
cd "$(dirname "$0")/../.."

MODE="sync"
NEW=""
case "${1:-}" in
    "")                ;;
    --check|-c)        MODE="check" ;;
    --set|-s)
        MODE="set"
        NEW="${2:-}"
        if ! [[ $NEW =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "用法: $0 [--check | --set X.Y.Z]" >&2
            exit 2
        fi
        ;;
    -h|--help)
        sed -n '2,10p' "$0"
        exit 0
        ;;
    *)
        echo "用法: $0 [--check | --set X.Y.Z]" >&2
        exit 2
        ;;
esac

# ---- --set：先改唯一版本源 / bump the single source of truth ----
if [ "$MODE" = "set" ]; then
    # ${1}/${2} 而不是 \1/\2：版本号紧跟其后时 \1 会和数字粘成 \12
    perl -pi -e 's|^(global WM_Version := ")[^"]*(")|${1}'"$NEW"'${2}|' wm.ahk
    printf 'sync_version: wm.ahk WM_Version -> v%s\n' "$NEW"
fi

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
CHANGELOGS=(docs/CHANGELOG.md docs/CHANGELOG-zh.md)
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
    if [ "$MODE" = "check" ]; then
        printf '  ! %s 版本号未同步:\n' "$f"
        diff -u "$f" "$tmp/$(basename "$f")" | sed -n '3,12p' | sed 's/^/      /' || true
    else
        cp "$tmp/$(basename "$f")" "$f"
        printf '  * %s -> v%s\n' "$f" "$V"
    fi
done

# CHANGELOG 标题不改写，但必须存在当前版本的条目。
for f in "${CHANGELOGS[@]}"; do
    if grep -q "^### v$V" "$f"; then
        printf '  = %s has v%s\n' "$f" "$V"
    else
        drift=1
        if [ "$MODE" = "check" ]; then
            printf '  ! %s 缺少 "### v%s" 条目\n' "$f" "$V"
        else
            printf '  * 提醒：%s 还没有 "### v%s" 条目\n' "$f" "$V"
        fi
    fi
done

if [ "$MODE" = "check" ]; then
    if (( drift )); then
        echo "sync_version: v$V 检查未通过（跑 $0 同步文档，或补 CHANGELOG 条目）" >&2
        exit 1
    fi
    echo "sync_version: v$V 文档与 CHANGELOG 检查通过"
else
    echo "sync_version: 已同步到 v$V（wm.ahk 为权威源）"
fi
