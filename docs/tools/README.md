# Tools Index / 工具索引

辅助脚本与测试工具。都不参与 `wm.ahk` 的运行时，只用于开发、验证和排障。

| Tool | 用途 | 依赖 / 备注 |
|---|---|---|
| `validate.sh` | 纯语法检查（`AutoHotkey64.exe /validate`），不执行脚本 | AutoHotkey v2 |
| `sync_version.sh` | 版本号唯一源同步：`--set X.Y.Z` 改 `wm.ahk` 并同步文档，`--check` 检查文档漂移与 CHANGELOG 条目 | bash + perl |
| `release.sh` | 发布链：`--set` 版本 → 检查 → 语法 → 断言 → Ahk2Exe 编译；`--commit` / `--publish` 才动 git | Ahk2Exe、AutoHotkey v2 |
| `mk_testslots.sh` | 从 `wm.ahk` 抽取纯函数，重建 `test_slots.ahk` | bash + awk |
| `run_testslots.sh` | 运行槽位/方向数学断言（不移动窗口） | AutoHotkey v2、PowerShell |
| `test_slots_body.ahk` | 断言主体（手写）；`test_slots.ahk` 是生成物，已 gitignore | — |
| `probe_pick.ahk` | 对比旧/新方向选取算法，随机布局 diff 探针 | AutoHotkey v2 |
| `check_borders.ps1` | 列出所有 `AHKWM_BORDER` 边框窗口，排查泄漏 | PowerShell |
| `migrate_config.py` | 把旧 `wm_config.ini` 合并到当前 `DefaultIni`，输出 UTF-16 | Python 3 |
| `ahk-error-watcher.ahk` | 监控 AHK 报错弹窗：截图 → OCR → 记录原文 → 自动关闭 | `ocr.ps1`、PowerShell 5.1 |
| `ocr.ps1` | Windows.Media.Ocr 封装（截图或读 PNG → 文本） | PowerShell 5.1、系统 OCR 语言包 |
| `gif.bat` | FFmpeg 两遍调色板 GIF 转换示例 | ffmpeg |
| `AI-NOTES.md` | 给 AI 的开发注意事项（编码、ByRef、`//`、`/validate`、强制缩放、错误弹窗等） | — |
| `user-scripts/` | 个人启动脚本与依赖（StartUP / Launcher / GuiPing / PrintScreen / OSD 通知） | 见子目录 README |

常用命令：

```bash
bash docs/tools/validate.sh
bash docs/tools/run_testslots.sh
bash docs/tools/sync_version.sh --check
bash docs/tools/release.sh 2.13.0 --commit --publish
```
