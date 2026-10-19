# GitHub GHClone 🇨🇳 国内 GitHub 加速

国内访问 GitHub 慢、`clone`/`fetch` 掉线、`Recv failure: 连接被对方重置`、直连 0 字节——用这个。

核心：**自动轮换多个 GitHub 加速前缀 + 每个前缀重试 3 次**，单个前缀挂死不卡死，自动换下一个。同时配置 git 全局静态加速，让普通 `git clone` 也直接受益。

## 特性

- `ghclone` 脚本：逐个前缀探测 → 可用即 clone → 失败自动换下一个，全失败才报错
- 带重试：应对代理「连接被重置」这类瞬时故障
- git 全局 `url.insteadOf`：不用别名，普通 `git clone https://github.com/...` 也走加速
- git 别名 `gclone`：一条命令触发自动轮换
- 前缀可配：`PATS` 数组 / git 配置随时增删

## 快速开始

```bash
# 1. 拉取本仓库（先走任意一个前缀）
git clone https://gh-proxy.com/https://github.com/lg0219/github-ghclone.git
cd github-ghclone

# 2. 一键安装（装到 ~/bin + 配 git 全局加速 + 别名）
bash scripts/install.sh
source ~/.bashrc

# 3. 用
ghclone https://github.com/owner/repo.git --depth 1   # 自动选可用前缀
# 或
git gclone https://github.com/owner/repo.git
# 或普通 git（已被全局加速）
git clone https://github.com/owner/repo.git
```

## 当前实测可用前缀（2026-10，随时会变）

| 前缀 | 示例 |
|---|---|
| `https://gh-proxy.com` | `https://gh-proxy.com/https://github.com/octocat/Hello-World.git` |
| `https://ghfast.top` | `https://ghfast.top/https://github.com/octocat/Hello-World.git` |
| `https://ghproxy.net` | `https://ghproxy.net/https://github.com/octocat/Hello-World.git` |

> 这些是社区代理，**时有时无**。`ghclone` 的轮换+重试正是为应对不稳定。

## 验证哪个前缀能用

```bash
for p in https://gh-proxy.com https://ghfast.top https://ghproxy.net; do
  echo "$p -> $(git ls-remote "$p/https://github.com/octocat/Hello-World.git" HEAD 2>/dev/null | head -1 || echo down)"
done
```

## 作为 OpenClaw / Agent 技能的默认行为

把本仓库放进 agent 的技能目录后，agent 遇到国内拉 GitHub（`git clone`/`gh`/下载 release 等）卡顿、掉线、`Recv failure: 连接被对方重置`、直连 0 字节时，会按 `SKILL.md` 自动：

1. **默认优先用 `ghclone` / `git gclone`** 拉取（自动轮换前缀 + 每前缀重试，挂死不卡死），而不是依赖单一静态前缀 `gh-proxy.com`。
2. 前缀失效时，先跑探测命令确认哪些还活着，再更新 `~/bin/ghclone` 的 `PATS=(...)` 与 git 全局 `url.insteadOf` 前缀。
3. 这些规则建议同时写进 agent 的工作区规则文件（如 OpenClaw 的 `AGENTS.md`），**重启网关/服务器后依旧生效**。

## 某前缀挂死时怎么换

```bash
# 1) 改 ghclone 候选前缀：编辑 ~/bin/ghclone 里的 PATS=(...)
# 2) 换 git 全局静态前缀：
git config --global url."https://新前缀/https://github.com/".insteadOf "https://github.com/"
git config --global --unset url."https://旧前缀/https://github.com/".insteadOf
```

## 作为 OpenClaw / Agent 技能

本仓库带标准 `SKILL.md`。把目录放进 agent 的技能目录（如 OpenClaw 的 `~/.openclaw/skills/` 或 workspace `skills/`），agent 就会在遇到国内 GitHub 卡顿/掉线时按 `SKILL.md` 的流程自动诊断、配置、轮换。

## 目录

```
github-ghclone/
├── bin/ghclone        # 自动轮换 clone 脚本（可执行）
├── scripts/install.sh # 一键安装 + 配置 git
├── SKILL.md           # Agent 技能说明
├── README.md
├── LICENSE            # MIT
└── package.json
```

## 局限与合规

- 前缀代理是第三方社区服务，可用性/速度/存续时间不可控；全失效时请找新前缀替换。
- 只加速 `github.com` 的 git 访问；`objects.githubusercontent.com`（Release 大文件）同理可用前缀包一层。
- 请确保使用符合当地法规的出网方式。
