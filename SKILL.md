---
name: github-ghclone
description: 国内（中国大陆网络）GitHub 访问慢、clone/fetch 掉线时的加速方案。自动轮换 GitHub 加速前缀并带重试，配好 git 全局静态加速 + ghclone 别名。
version: "1.0.0"
---

# GitHub GHClone - 国内 GitHub 加速技能

## 适用场景

当用户在国内网络环境遇到以下情况时启用：

- `git clone https://github.com/...` 慢、卡住、`Recv failure: 连接被对方重置`、超时
- 直连 GitHub 网页 / API 不稳定或完全被墙（`curl https://github.com` 0 字节）
- 需要批量拉取 GitHub 仓库、Release 文件、raw 文件

核心思路：把 `github.com` 的访问改走国内可直达的「加速前缀（mirror proxy）」，并对多个前缀做**自动轮换 + 重试**。单个前缀挂死时不卡死，自动换下一个。

## 一键安装

```bash
# 把本仓库 clone 下来（用任意可用前缀先拉本仓库也行）
git clone https://gh-proxy.com/https://github.com/OWNER/github-ghclone.git
cd github-ghclone
bash scripts/install.sh
source ~/.bashrc   # 让 ~/bin 生效
```

安装后得到：
- `~/bin/ghclone` —— 可执行脚本（自动轮换 3 个前缀，每前缀重试 3 次）
- git 全局静态加速 `url."https://gh-proxy.com/https://github.com/".insteadOf`（普通 `git clone` 直接受益）
- git 别名 `gclone` → `ghclone`

## 使用

```bash
# 方式一：直接调用脚本
ghclone https://github.com/owner/repo.git --depth 1

# 方式二：git 别名
git gclone https://github.com/owner/repo.git --depth 1

# 普通 git 命令（已被全局加速，无需别名）
git clone https://github.com/owner/repo.git
```

`ghclone` 会自动探测哪个前缀当前可用，成功即返回，全失败才报错。

## 手动配置（不想跑 install.sh 时）

1. **下载脚本**（本仓库自带 `bin/ghclone`），放到 `~/bin/` 并 `chmod +x`。
2. **git 全局静态加速**（任选一个当前可用的前缀）：
   ```bash
   git config --global url."https://gh-proxy.com/https://github.com/".insteadOf "https://github.com/"
   ```
3. **git 别名**：
   ```bash
   git config --global alias.gclone '!~/bin/ghclone'
   ```
4. **PATH**：确保 `~/bin` 在 `PATH`（追加到 `~/.bashrc`）：
   ```bash
   export PATH="$HOME/bin:$PATH"
   ```

## 更换 / 增删前缀（某前缀挂死时）

加速前缀是社区维护的代理，**时有时无**，需要能轮换：

- 改 `~/bin/ghclone`（或本仓库 `bin/ghclone`）里的 `PATS=(...)` 数组，增删前缀。
- 改 git 全局静态前缀：
  ```bash
  # 换成新的可用前缀
  git config --global url."https://新前缀/https://github.com/".insteadOf "https://github.com/"
  # 清掉旧前缀
  git config --global --unset url."https://旧前缀/https://github.com/".insteadOf
  ```

## 验证前缀是否可用

对每个前缀跑一次真实小仓库探测（返回 commit hash 即为可用，0 字节/报错为不可用）：

```bash
for p in https://gh-proxy.com https://ghfast.top https://ghproxy.net; do
  n=$(git ls-remote "$p/https://github.com/octocat/Hello-World.git" HEAD 2>/dev/null | head -1)
  echo "$p -> ${n:-不可用}"
done
```

## 已知可用前缀（2026-10 实测，随时会变）

| 前缀 | 用法 |
|---|---|
| `https://gh-proxy.com` | `https://gh-proxy.com/https://github.com/owner/repo.git` |
| `https://ghfast.top` | `https://ghfast.top/https://github.com/owner/repo.git` |
| `https://ghproxy.net` | `https://ghproxy.net/https://github.com/owner/repo.git` |

> 直连 `github.com` 在国内通常 0 字节（被墙），务必走前缀。前缀服务不稳定，`ghclone` 的重试逻辑就是为了应对这种「连接被对方重置」的瞬时故障。

## 局限与注意

- 前缀代理是第三方社区服务，可用性、速度、存续时间不可控；若全部失效，需寻找新前缀替换 `PATS`。
- 只加速 `github.com` 的 git 协议访问；`objects.githubusercontent.com`（Release 大文件）等子域同理可用前缀包一层。
- 合规提示：请确保使用符合当地法规的出网方式。
