# actlog · 兼容入口

本项目的 Agent 规范只有一个真源：**[`AGENTS.md`](AGENTS.md)**。

请先完整读完 `AGENTS.md` 再动手。本文件**不承载任何规则正文**，只做指向，避免双真源漂移。

速览（细节全部见 `AGENTS.md`）：

| 章节 | 内容 |
|---|---|
| §2 铁律 R1–R8 | 写集纪律（控制器不改 `apps\`/`packages\`）、门禁硬判据、分发禁令、不删文件、证据纪律（`ACTLOG_TEXT_SCALE`，旧名 `PRACTILOG_TEXT_SCALE` 仍兼容；两者都 ≠ 显示缩放）、复选框只控制器打、**项目边界（文件不出项目目录、不执行其它项目任务）**、派工契约 |
| §3 验证装置地图 | 判据 → 装置 → 期望：`tools\gates\g1–g4`、`tools\verify\*`、`tools\build\make_installer.ps1`、`reports\task21-*.ps1` |
| §4 目录与工具索引 | `apps\desktop`、`packages\core_{domain,db,data}`、`tools\`、`docs\`、`reports\`、`design-demos\`、`release\` |
| §5 本机工具坑速查 | 15 条已踩过的坑 |
| §6 权威文档导航 | 冲突时的优先级：用户当轮决定 > 派工书 > 计划正文 > handoff > README；证据：实测 > 运行时产物 > 源码 > 文档转述 |
| §7 当前状态快照 | Task 24 收口后状态（计划文件 `F8C34C20DFDD454C`，Task 1–3 已全打勾、仅 `7041` 挂账）、`+219` / `+141`、唯一可分发安装包 |

常用命令（镜像必须进程内设置）：

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze      # 期望逐字 No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact   # 基线 +219
```

跑全量前先把 `apps\desktop\build\test_cache\build` **改名挪走**（`Move-Item`，不删），否则 OS Error 183 挂死。