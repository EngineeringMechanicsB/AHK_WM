#!/usr/bin/env bash
# 一键发布：bump 版本 → 同步文档 → 语法检查 → 跑断言 → 编译 exe。
# 提交/打标签只在显式 --commit 时执行，推送与 gh release 只在显式 --publish 时执行
# （项目规矩：不自动 push）。两步可以一起给：--commit --publish。
#
#   bash docs/tools/release.sh 2.12.0                    # 只出包，不动 git
#   bash docs/tools/release.sh 2.12.0 --commit           # 再 commit + tag v2.12.0
#   bash docs/tools/release.sh 2.12.0 --commit --publish  # 再 push + gh release create
#
# 环境变量：
#   AHK2EXE    Ahk2Exe.exe 路径（默认 /c/Program Files/AutoHotkey/Compiler/Ahk2Exe.exe）
#   AHK_V2_DIR AutoHotkey v2 安装目录（默认 /c/Program Files/AutoHotkey/v2），
#              用它的 AutoHotkey64.exe / AutoHotkey32.exe 当 base —— v1 那套
#              Compiler\Unicode NN-bit.bin 是 v1 base，编译 v2 脚本会失败
#   AHKWM_ICON exe 图标路径（默认无图标）
set -euo pipefail
cd "$(dirname "$0")/../.."
# 关掉 MSYS 的路径改写，否则 /in /out 会被换成 C:/Program Files/Git/in 之类
export MSYS2_ARG_CONV_EXCL='*'

VERSION=""
DO_COMMIT=0
DO_PUBLISH=0
for a in "$@"; do
    case "$a" in
        --commit)  DO_COMMIT=1 ;;
        --publish) DO_PUBLISH=1 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        -*)        echo "未知参数: $a" >&2; exit 2 ;;
        *)         VERSION="$a" ;;
    esac
done
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "用法: $0 <X.Y.Z> [--commit] [--publish]" >&2
    exit 2
fi
if (( DO_PUBLISH )) && ! (( DO_COMMIT )); then
    echo "release: --publish 需要同时给 --commit（发布要对应一个 tag）" >&2
    exit 2
fi

step() { printf '\n=== %s ===\n' "$1"; }

# ---- 0. 工作区必须干净，否则版本提交里会混进无关改动 ----
step "0/6 前置检查"
if [ -n "$(git status --porcelain)" ]; then
    echo "release: 工作区有未提交改动，先提交或 stash 再发布：" >&2
    git status --short >&2
    exit 1
fi
if (( DO_PUBLISH )) && [ "$(git branch --show-current)" != "main" ]; then
    echo "release: 当前分支不是 main（$(git branch --show-current)）" >&2
    exit 1
fi
if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
    echo "release: 标签 v$VERSION 已存在（换版本号，或先 git tag -d v$VERSION）" >&2
    exit 1
fi
CUR=$(grep -m1 '^global WM_Version :=' wm.ahk | sed -E 's/.*"([^"]+)".*/\1/')
if [ "$CUR" != "$VERSION" ] && [ "$(printf '%s\n%s\n' "$CUR" "$VERSION" | sort -V | tail -n1)" != "$VERSION" ]; then
    echo "release: v$VERSION 不比当前 v$CUR 新（要回退版本请直接改 wm.ahk）" >&2
    exit 1
fi
echo "工作区干净，分支 $(git branch --show-current)，当前版本 v$CUR"

# ---- 1. bump 唯一版本源 + 同步文档 ----
step "1/6 bump WM_Version -> v$VERSION 并同步文档"
bash docs/tools/sync_version.sh --set "$VERSION"

# ---- 2. 版本一致性检查（含 CHANGELOG 条目）----
step "2/6 检查版本号与 CHANGELOG"
bash docs/tools/sync_version.sh --check

# ---- 3/4. 校验 ----
step "3/6 语法检查 validate.sh"
bash docs/tools/validate.sh
step "4/6 断言 run_testslots.sh"
bash docs/tools/run_testslots.sh

# ---- 5. 编译 ----
step "5/6 Ahk2Exe 编译"
AHK2EXE=${AHK2EXE:-/c/Program Files/AutoHotkey/Compiler/Ahk2Exe.exe}
[ -x "$AHK2EXE" ] || { echo "release: 找不到 $AHK2EXE" >&2; exit 1; }
AHK_V2_DIR=${AHK_V2_DIR:-/c/Program Files/AutoHotkey/v2}
[ -d "$AHK_V2_DIR" ] || { echo "release: 找不到 v2 安装目录 $AHK_V2_DIR" >&2; exit 1; }
ROOT=$(pwd -W 2>/dev/null || pwd)   # Ahk2Exe 要 Windows 路径 / Ahk2Exe needs Windows paths
mkdir -p dist
for arch in 64 32; do
    base="$AHK_V2_DIR/AutoHotkey$arch.exe"
    [ -f "$base" ] || { echo "release: 缺 base 文件 $base" >&2; exit 1; }
    out="dist/wm$arch.exe"
    args=(/in "$ROOT/wm.ahk" /out "$ROOT/$out" /base "$(cygpath -w "$base" 2>/dev/null || echo "$base")")
    if [ -n "${AHKWM_ICON:-}" ]; then
        args+=(/icon "$(cygpath -w "$AHKWM_ICON" 2>/dev/null || echo "$AHKWM_ICON")")
    fi
    "$AHK2EXE" "${args[@]}" /silent
    if [ ! -f "$out" ]; then
        echo "release: 编译 $out 失败" >&2
        exit 1
    fi
    size=$(stat -c %s "$out")
    if [ "$size" -lt 200000 ]; then
        echo "release: $out 只有 $size 字节，不像编译成功的产物" >&2
        exit 1
    fi
    printf '  %-16s %9s 字节\n' "$out" "$size"
done

# ---- 6. 提交 / 发布 ----
step "6/6 提交与发布"
if ! (( DO_COMMIT )); then
    echo "跳过 commit/tag（未给 --commit）。产物在 dist/，版本号已 bump 但未提交。"
    echo "回滚版本号：git checkout -- wm.ahk README.md docs/"
    exit 0
fi
git add -A
git commit -m "chore: 发布 v$VERSION

Co-Authored-By: Claude Code <noreply@anthropic.com>"
git tag -a "v$VERSION" -m "v$VERSION"
echo "已提交并打标签 v$VERSION（尚未推送）"

if ! (( DO_PUBLISH )); then
    echo "跳过 push / gh release（未给 --publish）。要发布：git push && git push origin v$VERSION"
    echo "  gh release create v$VERSION dist/wm32.exe dist/wm64.exe --title \"v$VERSION\" --notes-file -"
    exit 0
fi
gh auth status >/dev/null 2>&1 || { echo "release: gh 未登录，先 gh auth login（提交与标签已建好，尚未推送）" >&2; exit 1; }
git push
git push origin "v$VERSION"
# release notes = CHANGELOG 里该版本的条目；走临时文件，免得长文本经 shell 传递
notes=$(mktemp); trap 'rm -f "$notes"' EXIT
awk -v v="### v$VERSION" '
    on && /^### v/ { exit }
    index($0, v) == 1 { on = 1 }
    on { print }
' docs/CHANGELOG.md > "$notes"
[ -s "$notes" ] || printf 'v%s\n' "$VERSION" > "$notes"
gh release create "v$VERSION" dist/wm32.exe dist/wm64.exe \
    --title "AHK WM v$VERSION" --notes-file "$notes"
echo "已发布 v$VERSION"
