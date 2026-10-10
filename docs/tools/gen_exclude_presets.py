#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 komorebi-application-specific-configuration 的 applications.yaml
生成 AHK_WM 的窗口排除预设。

komorebi 的条目结构（每个应用一块）：
  - name: <应用名>
    identifier:                 # 该应用"要被管理"的主窗口标识
      kind: Exe|Class|Title
      id: <值>
      matching_strategy: Equals|Legacy|Contains|StartsWith|EndsWith|Regex
    options:                    # 可选
    - force | layered | tray_and_multi_window | object_name_change | ...
    float_identifiers:          # 该应用里"应浮动(不参与平铺)"的窗口 —— 这才是排除项
    - kind: ...
      id: ...

谁算"排除"：
  * float_identifiers 里的全部条目
  * options 里含 force 或 layered 的应用，其 identifier 也算（komorebi 里这两个选项
    就是强制浮动）
  注意：单独的 identifier（如 chrome.exe / Code.exe / explorer.exe）是"要被管理"的，
        绝不能当排除项，否则把用户的主窗口全排除了。

输出：
  1) exclude.ini 的预设段文本（[Preset-Titles] / [Preset-Classes] / [Preset-Processes]）
  2) wm.ahk 里 global ExclPresetIniText 的字面量片段（供脚本首次生成 exclude.ini 用）

用法：
  python gen_exclude_presets.py <applications.yaml> [--mode floats|all] [--ini out] [--ahk out]

  --mode floats （默认，推荐）只取上面的"真排除项"
  --mode all    额外的把每个应用的 identifier 也当排除项（= komorebi 里的"全部应用"，
                会连 chrome.exe / Code.exe / explorer.exe 一起排除，慎用）

匹配策略映射（komorebi -> AHK_WM 规则前缀）：
  Equals            -> =value
  Contains / Legacy -> value          （子串包含）
  StartsWith        -> value*         （通配）
  EndsWith          -> *value         （通配）
  Regex             -> ~=value        （正则）
"""
import argparse
import re
import sys

RE_NAME = re.compile(r'^- name:\s*(.+)$')
RE_SECTION = re.compile(r'^  ([A-Za-z_]+):\s*$')          # identifier / options / float_identifiers
RE_OPTION = re.compile(r'^  - ([A-Za-z_]+)\s*$')          # options 列表项
RE_ITEM_KIND = re.compile(r'^(\s*)(?:-\s+)?kind:\s*(\w+)\s*$')
RE_ITEM_ID = re.compile(r'^\s*(?:-\s+)?id:\s*(.+?)\s*$')
RE_ITEM_STRAT = re.compile(r'^\s*(?:-\s+)?matching_strategy:\s*(\w+)\s*$')
# komorebi 的复合浮动标识："- - kind: X" 开头的嵌套列表 = 该组内所有条件必须同时成立
# （AND），AHK_WM 的规则模型表达不了 → 整组跳过。按单条展平会变成整进程排除
# （踩过：Zen/Firefox 的 "Title==Picture-in-Picture AND Exe==zen.exe" 被展平成 =zen.exe，
#  结果整个浏览器进程被排除）。
RE_FLOAT_COMPOSITE = re.compile(r'^  - - ')
RE_KV = re.compile(r'(kind|id|matching_strategy):\s*(.*)$')
RE_KV_IND = re.compile(r'^    ' + RE_KV.pattern)   # 普通条目的 4 空格续行

KIND_BUCKET = {'Exe': 'Processes', 'Class': 'Classes', 'Title': 'Titles'}
# komorebi 的 options 里，只有 force 是明确的"强制浮动"。
# layered 是"该应用有 WS_EX_LAYERED 窗口"，komorebi 逐窗口处理，不是整进程浮动；
# 若按进程排除会把 Excel/Word/Outlook/PPT/Discord 全排除掉，故不采用。
FORCE_FLOAT_OPTIONS = {'force'}


def _unquote(v):
    """去掉 YAML 的单/双引号包裹（如 id: '#32770'）"""
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ('\'', '"'):
        return v[1:-1]
    return v


def _apply_kv(m, items, pending_kind, fresh_id):
    """把一行 kind:/id:/matching_strategy: 应用到 items 列表，返回新的 (pending_kind, fresh_id)"""
    k, v = m.group(1), _unquote(m.group(2).strip())
    if k == 'kind':
        return v, False
    if k == 'id':
        items.append([pending_kind, v, None])
        return pending_kind, True
    if k == 'matching_strategy':
        if fresh_id and items:
            items[-1][2] = v
        return pending_kind, False
    return pending_kind, fresh_id


def parse(yaml_path, mode):
    """返回 (buckets, stats, meta)"""
    buckets = {'Processes': set(), 'Classes': set(), 'Titles': set()}
    stats = {'Equal': 0, 'Contains': 0, 'Legacy': 0, 'Start': 0, 'End': 0, 'Regex': 0}
    meta = {'apps': 0, 'floats': 0, 'forced': 0, 'skipped': 0}

    cur = None            # 当前应用
    sec = None            # 当前二级段
    pending_kind = None   # 当前条目块的 kind（在 id 行之前出现）
    fresh_id = False
    composite = False     # 是否在"复合浮动标识"（AND）组里 —— 整组跳过

    def flush_item(kind, val, strat):
        strat = strat or 'Legacy'
        bucket = KIND_BUCKET.get(kind)
        rule = to_rule(strat, val)
        if bucket is None or rule is None or val == '':
            meta['skipped'] += 1
            return
        buckets[bucket].add(rule)
        stats[_stat_key(strat)] += 1

    def close_app(app):
        if app is None:
            return
        meta['apps'] += 1
        forced = bool(FORCE_FLOAT_OPTIONS & set(app['options']))
        # float_identifiers 全是排除
        for kind, val, strat in app['floats']:
            flush_item(kind, val, strat)
            meta['floats'] += 1
        # force/layered 选项 → identifier 也是排除
        if forced and app['ident']:
            kind, val, strat = app['ident']
            flush_item(kind, val, strat)
            meta['forced'] += 1
        elif mode == 'all' and app['ident']:
            kind, val, strat = app['ident']
            flush_item(kind, val, strat)

    with open(yaml_path, encoding='utf-8') as fh:
        for ln in fh:
            ln = ln.rstrip('\n')
            m = RE_NAME.match(ln)
            if m:
                close_app(cur)
                cur = {'name': m.group(1), 'ident': None, 'floats': [], 'options': []}
                sec, pending_kind, fresh_id, composite = None, None, False, False
                continue
            if cur is None:
                continue
            m = RE_SECTION.match(ln)
            if m:
                sec = m.group(1)
                pending_kind, fresh_id, composite = None, False, False
                continue
            if sec == 'options':
                m = RE_OPTION.match(ln)
                if m:
                    cur['options'].append(m.group(1))
                continue
            if sec == 'identifier':
                m = RE_ITEM_KIND.match(ln)
                if m:
                    pending_kind = m.group(2)
                    fresh_id = False
                    continue
                m = RE_ITEM_ID.match(ln)
                if m:
                    cur['ident'] = [pending_kind, _unquote(m.group(1)), None]
                    fresh_id = True
                    continue
                m = RE_ITEM_STRAT.match(ln)
                if m and fresh_id and cur['ident']:
                    cur['ident'][2] = m.group(1)
                    fresh_id = False
                continue
            if sec == 'float_identifiers':
                # 复合组（AND）整组跳过
                if RE_FLOAT_COMPOSITE.match(ln):
                    composite = True
                    continue
                if ln.startswith('  - '):
                    composite = False
                    m = RE_KV.match(ln[4:])
                    if m:
                        pending_kind, fresh_id = _apply_kv(
                            m, cur['floats'], pending_kind, fresh_id)
                    continue
                if composite:
                    continue
                # 普通条目的 4 空格续行（id / matching_strategy）
                m = RE_KV_IND.match(ln)
                if m:
                    pending_kind, fresh_id = _apply_kv(
                        m, cur['floats'], pending_kind, fresh_id)
                continue
        close_app(cur)

    return buckets, stats, meta


def _stat_key(strat):
    return {'Equals': 'Equal', 'Contains': 'Contains', 'Legacy': 'Legacy',
            'StartsWith': 'Start', 'EndsWith': 'End', 'Regex': 'Regex'}.get(strat, 'Legacy')


def to_rule(strat, val):
    if strat == 'Equals':
        return '=' + val
    if strat == 'StartsWith':
        return val + '*'
    if strat == 'EndsWith':
        return '*' + val
    if strat == 'Regex':
        return '~=' + val
    if strat in ('Contains', 'Legacy'):
        return val
    return None   # DoesNotEqual 等 AHK_WM 表达不了的策略 → 丢弃


def ini_section(name, rules):
    out = ['[Preset-' + name + ']']
    for i, r in enumerate(sorted(rules), 1):
        out.append('%d=%s' % (i, r))
    out.append('')
    return '\r\n'.join(out)


def build_ini(buckets):
    return '\r\n'.join(ini_section(n, buckets[n]) for n in ('Titles', 'Classes', 'Processes'))


def ahk_escape(s):
    return s.replace('`', '``').replace('"', '`"')


def build_ahk(text):
    lines = text.split('\r\n')
    out = ['global ExclPresetIniText := ""']
    for ln in lines:
        out.append('    . "%s`r`n"' % ahk_escape(ln))
    return '\r\n'.join(out) + '\r\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('yaml')
    ap.add_argument('--mode', choices=['floats', 'all'], default='floats')
    ap.add_argument('--ini')
    ap.add_argument('--ahk')
    args = ap.parse_args()

    buckets, stats, meta = parse(args.yaml, args.mode)
    for k in ('Processes', 'Classes', 'Titles'):
        print('%-10s %d' % (k, len(buckets[k])))
    print('apps:', meta['apps'], 'floats:', meta['floats'],
          'forced(force/layered):', meta['forced'], 'skipped:', meta['skipped'])
    print('strategies:', stats)

    ini = build_ini(buckets)
    if args.ini:
        open(args.ini, 'w', encoding='utf-8', newline='').write(ini)
        print('wrote', args.ini)
    if args.ahk:
        ahk = build_ahk(ini)
        open(args.ahk, 'w', encoding='utf-8', newline='').write(ahk)
        print('wrote', args.ahk, len(ahk), 'bytes')

    risky = [(k, r) for k, vs in buckets.items() for r in vs
             if ' ;' in r or '"' in r or '`' in r or r != r.strip()]
    if risky:
        print('!! 风险字符:', file=sys.stderr)
        for k, r in risky:
            print('   ', k, repr(r), file=sys.stderr)
    else:
        print('风险字符检查: 通过')


if __name__ == '__main__':
    main()
