#!/usr/bin/env bash
# install.sh - 把 ghclone 装到 ~/bin 并配置 git 全局加速
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$HOME/bin/ghclone"
PREFIX="https://gh-proxy.com"   # 默认静态前缀，可改

mkdir -p "$HOME/bin"
cp "$REPO/bin/ghclone" "$BIN"
chmod +x "$BIN"
echo "[install] ghclone -> $BIN"

# 确保 ~/bin 在 PATH（bashrc 幂等追加）
if ! grep -q '\$HOME/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  echo "[install] 已把 ~/bin 加入 .bashrc PATH"
fi

# git 全局静态加速（普通 git clone 也受益）；失效可 unset
git config --global url."$PREFIX/https://github.com/".insteadOf "https://github.com/"
echo "[install] git 全局加速前缀: $PREFIX"
# git 别名
git config --global alias.gclone "!'$BIN'"
echo "[install] git 别名 gclone 已配置"

# 自检
if git ls-remote "$PREFIX/https://github.com/octocat/Hello-World.git" HEAD >/dev/null 2>&1; then
  echo "[install] 自检通过：$PREFIX 可用"
else
  echo "[install] 自检失败：$PREFIX 当前不通，ghclone 会自动换前缀，也可手动改 PATS"
fi
