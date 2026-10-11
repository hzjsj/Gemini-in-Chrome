# Gemini in Chrome

一键解锁 Chrome 内置 Gemini（Glic）侧边栏的小工具，适用于非美国地区用户。

## 快速开始

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/hzjsj/Gemini-in-Chrome/main/install.sh | bash
```

`raw.githubusercontent.com` 在部分地区无法直连——如果上面的命令卡住，请使用 jsDelivr 镜像：

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/hzjsj/Gemini-in-Chrome@main/install.sh | bash
```

### Windows

打开 PowerShell 执行：

```powershell
irm https://raw.githubusercontent.com/hzjsj/Gemini-in-Chrome/main/install.ps1 | iex
```

如果该地址无法访问，使用 jsDelivr 镜像：

```powershell
irm https://cdn.jsdelivr.net/gh/hzjsj/Gemini-in-Chrome@main/install.ps1 | iex
```

## 它做了什么

1. ✅ 检查 Chrome 是否在运行（提示你先彻底退出）
2. 💾 备份配置文件（`Local State.bak`）
3. 🔧 修改以下 3 个字段：
   - `is_glic_eligible`：`false` → `true`
   - `variations_country`：→ `us`
   - `variations_permanent_consistency_country`：→ `us`
4. ✓ 校验修改是否生效

## 日常使用（macOS）

补丁不是永久生效的：Chrome 每次启动都会重新计算 Glic 资格，而且国家覆盖参数只在单次启动有效。请先彻底退出 Chrome（Cmd+Q），再用以下脚本启动：

```bash
bash launch-glic.sh
```

如果侧边栏提示「未在你所处的地区推出」，先检查你的代理节点：

```bash
bash check-region.sh   # 换节点后重新运行，直到结果显示可用
```

## 脚本一览

| 脚本 | 作用 |
|------|------|
| `install.sh` / `install.ps1` | 一次性修改 `Local State` 中的 3 个字段 |
| `launch-glic.sh` | macOS 日常启动器：重新补丁并以 `--variations-override-country=us --enable-features=Glic` 启动 Chrome |
| `check-region.sh` | 检测 Google 的地理服务把你的代理出口判定为哪个地区（参考性预筛） |

## 故障排查

Chrome 版 Gemini（Glic）背后有多道门槛，必须全部通过：

1. **客户端资格标志** —— `Local State` 里的 `is_glic_eligible`（每个资料各一份）、`variations_country` 和 `variations_permanent_consistency_country`。`install.sh` 负责修改，但 Chrome 每次启动都会重新计算，所以只打一次补丁是留不住的。
2. **实验配置过滤** —— finch 种子本身是全球通用的，按国家过滤发生在 Chrome 客户端。`launch-glic.sh` 通过 `--variations-override-country=us` 强制按美国过滤。
3. **服务端地区判定** —— Gemini 后端会用 Google 自己的地理库检测出口 IP，结论经常和 ipinfo/MaxMind 不一致：中国运营商国际机房出口（CTG/CMI/CN2，中转/IEPL 节点常见）在 ipinfo 显示「美国」，在 Google 却按「中国」处理。典型症状：侧边栏能打开，但提示「未在你所处的地区推出」。解决办法：换「原生 IP」节点，再用 `launch-glic.sh` 重启 Chrome，等一两分钟。
4. **账号登录** —— 必须登录 Google 账号。（新版 Chrome 中文界面也可用。）

## 还原原始配置

**macOS：**

```bash
mv ~/Library/Application\ Support/Google/Chrome/Local\ State.bak \
   ~/Library/Application\ Support/Google/Chrome/Local State
```

**Linux：**

```bash
mv ~/.config/google-chrome/Local\ State.bak \
   ~/.config/google-chrome/Local State
```

**Windows PowerShell：**

```powershell
Move-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State.bak" `
          -Destination "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State" -Force
```

## 安全性

- 修改前自动备份原始配置
- 只修改本地 Chrome 设置
- 不上传任何数据，无网络访问（下载脚本本身除外）
- 随时可还原
- 非官方开源工具，请自行承担使用风险

## 配置文件路径

| 系统 | 路径 |
|------|------|
| macOS | `~/Library/Application Support/Google/Chrome/Local State` |
| Linux | `~/.config/google-chrome/Local State` |
| Windows | `%LOCALAPPDATA%\Google\Chrome\User Data\Local State` |

## 问题反馈

发现 bug？[提交 issue](https://github.com/hzjsj/Gemini-in-Chrome/issues)。

## 许可证

MIT
