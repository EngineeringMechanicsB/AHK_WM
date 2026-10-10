#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把旧版 wm_config.ini 迁移到当前版本。

做法：以 wm.ahk 里的 DefaultIni 模板为骨架，用旧配置里**同名 section+key** 的值
覆盖模板默认值 —— 旧文件没有的新键自动补上默认值，模板里已经没有的旧键
（如 ToggleAllBorders / RestoreLayout）自动丢弃。

用法：
    python -I docs/tools/migrate_config.py <旧配置> <输出配置>

输出为 UTF-16（与脚本一致），并保留旧文件为 <输出配置>.v<旧版本>.bak。
"""
import io
import os
import re
import shutil
import sys

RE_SECTION = re.compile(r'^\[(.+?)\]\s*$')
RE_KEY = re.compile(r'^([^=;\s][^=]*?)\s*=\s*(.*)$')


def read_ini(path):
    """返回 {section: {key: value}} 与出现顺序 [{section, key, value}]。"""
    text = io.open(path, encoding='utf-16').read()
    if text.startswith('﻿'):
        text = text[1:]
    secs, order = {}, []
    cur = ''
    for line in text.splitlines():
        s = line.strip()
        m = RE_SECTION.match(s)
        if m:
            cur = m.group(1).strip()
            secs.setdefault(cur, {})
            continue
        if not s or s.startswith(';'):
            continue
        m = RE_KEY.match(s)
        if m:
            k, v = m.group(1).strip(), m.group(2)
            secs.setdefault(cur, {})[k] = v
            order.append((cur, k, v))
    return secs, order


def template_from_script(path):
    """从 wm.ahk 抽出 DefaultIni 的正文（不含首尾的 ( 与 )" ）。"""
    text = io.open(path, encoding='utf-8-sig').read()
    m = re.search(r'DefaultIni\s*:=\s*"\s*\r?\n\s*\(\r?\n(.*?)\r?\n\s*\)"',
                  text, re.S)
    if not m:
        raise SystemExit('wm.ahk: DefaultIni 模板没找到')
    return m.group(1)


# 迁移后强制覆盖的值：(section, key, value)
# 只强制版本号：热键这类东西用户可能自己改过（例如把诊断绑到某个键上），
# 迁移不该覆盖 —— 模板里的默认值本来就是想要的值。
FORCE = {
    ('General', 'ConfigVersion'): '3',
}


def build(tpl, old):
    out, cur, used = [], '', set()
    for line in tpl.split('\n'):
        s = line.strip()
        m = RE_SECTION.match(s)
        if m:
            cur = m.group(1).strip()
            out.append(line)
            continue
        m = RE_KEY.match(s)
        if not m:
            out.append(line)
            continue
        k = m.group(1).strip()
        val = None
        if cur in old and k in old[cur]:
            val = old[cur][k]
            used.add((cur, k))
        if (cur, k) in FORCE:
            val = FORCE[(cur, k)]
        out.append('%s=%s' % (k, val) if val is not None else line)
    return out, used


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    old_path, out_path = sys.argv[1], sys.argv[2]
    old, _ = read_ini(old_path)
    tpl = template_from_script(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), '..', '..', 'wm.ahk'))

    lines, used = build(tpl, old)

    # 旧文件里模板已不存在的键：列出来提醒，不写进新文件
    gone = [(s, k) for s in old for k in old[s] if (s, k) not in used]
    # 旧 [Exclude] 段保留：脚本首次生成 exclude.ini 时会把它迁走
    extra = []
    if 'Exclude' in old:
        extra = ['', '; Legacy exclusion rules, migrated into exclude.ini on first run',
                 '; 旧版排除段，首次运行时自动迁进 exclude.ini', '[Exclude]']
        for k, v in old['Exclude'].items():
            extra.append('%s=%s' % (k, v))
        extra.append('')

    if os.path.exists(out_path):
        bak = out_path + '.pre-migrate.bak'
        shutil.copyfile(out_path, bak)
        print('备份原文件 ->', bak)

    text = '\r\n'.join(lines + extra)
    io.open(out_path, 'w', encoding='utf-16', newline='').write(text)

    print('已写出', out_path, '(%d 字节)' % os.path.getsize(out_path))
    if gone:
        print('模板中已不存在的旧键（已丢弃）：')
        for s, k in gone:
            print('   [%s] %s' % (s, k))


if __name__ == '__main__':
    sys.exit(main())
