# User Startup Scripts / 个人启动脚本

从作者机器 `C:\Users\Administrator\Desktop\zxw\StartUp\` 复制的脚本，仅作归档/参考，
**不属于 AHK_WM 的构建产物**。脚本内是绝对路径，换机器需自行调整。

| Script | 作用 | 依赖 |
|---|---|---|
| `StartUP.ahk` | 登录启动管理器（Task Scheduler 调用），按列表启动/隐藏窗口 | `wm.ahk`、`osd-timed-notify.ahk`、`launcher_V1.2.ahk`、`GuiPing.ahk`、`PrintScreen_V1.1.ahk`；外部 ShareX / Listary / VS Code |
| `launcher_V1.2.ahk` | 应用启动器，`Alt+Space` 类界面，Tab 切换应用 | 首次运行自建 `%USERPROFILE%\.config\AHK_Launcher\launcher.ini`；`wt.exe` 路径在配置里 |
| `GuiPing.ahk` | `Win+E` 在 Windows Terminal 里开 yazi；`Alt+P` 打开 EMS 设备发现/Ping 面板 | `deps/sync-drives.ps1`、`deps/discovery_daemon.py`、`deps/add_subnet.ps1`；外部 `WindowsTerminal.exe`、`yazi.exe`、Python、PowerShell |
| `PrintScreen_V1.1.ahk` | 截图/录屏（区域选择、滚动截图、视频录制） | 首次运行自建 `%USERPROFILE%\.config\AHK_screenshot\screenshot.ini`；外部 `ffmpeg.exe`（**未上传**） |
| `osd-timed-notify.ahk` | OSD 定时通知调度器（间隔/每日/每周/单次） | 需要 `wm.ahk` 正在运行（走它的 `WM_COPYDATA` OSD 接口） |

## deps/

| File | 来源 / 用途 |
|---|---|
| `sync-drives.ps1` | 自动为每个盘符建 junction，生成 `C:\Users\Administrator\drives\C-系统` 这类目录供 yazi 使用 |
| `discovery_daemon.py` | EMS 设备发现守护进程，轮询网段并把在线设备写入 `devices.txt` |
| `add_subnet.ps1` | 给网卡临时加同网段 IP，使跨网段设备可 ping |

## 未包含

- `devices.txt` — 运行时生成，含具体设备 IP/MAC，**不上传**。
- `ffmpeg.exe` / `yazi.exe` / `WindowsTerminal.exe` / `fzf` 等外部二进制，**不上传**。
- `startup_log.txt`、`sync-drives.log` 等运行日志。
