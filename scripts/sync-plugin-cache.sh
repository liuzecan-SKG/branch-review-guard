#!/usr/bin/env bash
# 插件缓存 <-> 仓库 规则同步（方案 C）
#
# 背景：插件装在机器级 ~/.claude/plugins/cache/，多个 clone 共享同一份缓存。
# 规则改在缓存里能被所有 clone 立刻读到，但缓存无版本控制、重装即失——
# v0.8.0 就因此分叉过（缓存 23 条 / 仓库 19 条，4 条只存在于缓存）。
# 本脚本把"同步"变成一条命令，并提供分叉检测。
#
# ⚠ DLP 环境纪律（实测）：
#   - `cp` 复制出的文件是明文 ✅
#   - `echo >` / `>>` 重定向写出的文件会被 DLP 加密成 %TSD-Header ❌
#   本脚本只用 cp / diff，绝不用重定向写规则文件。
#
# 用法：
#   ./sync-plugin-cache.sh check     # 只报告差异，不改动（默认）
#   ./sync-plugin-cache.sh push      # 仓库 -> 缓存（发版后生效）
#   ./sync-plugin-cache.sh pull      # 缓存 -> 仓库（回收在缓存里改的规则）

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_VERSION="$(grep -m1 '"version"' "$REPO_DIR/.claude-plugin/plugin.json" | sed 's/.*"version"[^"]*"\([^"]*\)".*/\1/')"
CACHE_DIR="$HOME/.claude/plugins/cache/branch-review-guard/branch-review-guard/$PLUGIN_VERSION"

MODE="${1:-check}"

if [ ! -d "$CACHE_DIR" ]; then
  echo "✗ 插件缓存目录不存在：$CACHE_DIR"
  echo "  （版本号取自 plugin.json = $PLUGIN_VERSION；插件未安装或版本不符）"
  exit 1
fi

echo "仓库：$REPO_DIR/rules/"
echo "缓存：$CACHE_DIR/rules/  (v$PLUGIN_VERSION)"
echo

# ---- 分叉检测 ----
divergence=0
for pack in baseline skg-spring discover-new; do
  [ -d "$REPO_DIR/rules/$pack" ] || continue
  only_cache=$(comm -13 \
    <(cd "$REPO_DIR/rules/$pack" && ls *.md 2>/dev/null | sort) \
    <(cd "$CACHE_DIR/rules/$pack" && ls *.md 2>/dev/null | sort) || true)
  only_repo=$(comm -23 \
    <(cd "$REPO_DIR/rules/$pack" && ls *.md 2>/dev/null | sort) \
    <(cd "$CACHE_DIR/rules/$pack" && ls *.md 2>/dev/null | sort) || true)
  if [ -n "$only_cache" ]; then
    echo "⚠ [$pack] 只在缓存里（未入库，重装即失）："
    echo "$only_cache" | sed 's/^/    /'
    divergence=1
  fi
  if [ -n "$only_repo" ]; then
    echo "⚠ [$pack] 只在仓库里（缓存未更新，本次评审读不到）："
    echo "$only_repo" | sed 's/^/    /'
    divergence=1
  fi
  # 同名但内容不同（--strip-trailing-cr：安装时 git autocrlf 会把 LF 转 CRLF，
  # 那是无害的行尾符差异，不是内容分叉；不忽略会淹没真信号）
  for f in $(cd "$REPO_DIR/rules/$pack" && ls *.md 2>/dev/null); do
    if [ -f "$CACHE_DIR/rules/$pack/$f" ] && ! diff -q --strip-trailing-cr "$REPO_DIR/rules/$pack/$f" "$CACHE_DIR/rules/$pack/$f" >/dev/null 2>&1; then
      echo "⚠ [$pack] 内容不一致：$f"
      divergence=1
    fi
  done
done

# ---- skills/ commands/ agents/ 分叉检测 ----
# 规则之外，SKILL.md / prompt / 命令文件同样是"改了不同步就不生效"的重灾区：
# 缓存是插件的实际加载源，仓库改了不 push，跑的还是旧行为。
for dir in skills commands agents; do
  [ -d "$REPO_DIR/$dir" ] || continue
  while IFS= read -r rel; do
    if [ ! -f "$CACHE_DIR/$dir/$rel" ]; then
      echo "⚠ [$dir] 只在仓库里（缓存未更新）：$rel"
      divergence=1
    elif ! diff -q --strip-trailing-cr "$REPO_DIR/$dir/$rel" "$CACHE_DIR/$dir/$rel" >/dev/null 2>&1; then
      echo "⚠ [$dir] 内容不一致：$rel"
      divergence=1
    fi
  done < <(cd "$REPO_DIR/$dir" && find . -name '*.md' -type f | sed 's|^\./||')
done

# ---- config.yaml 冲突标记检测（v0.8.0 踩过） ----
if grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$CACHE_DIR/rules/config.yaml" 2>/dev/null; then
  echo "✗ 缓存 config.yaml 残留 git 冲突标记 —— YAML 语法非法，须立即修"
  divergence=1
fi

# ---- enabled 开关体检（v0.8.0 踩过：晋升只搬文件没开开关） ----
disabled=$(cd "$CACHE_DIR/rules/discover-new" 2>/dev/null && grep -l '^enabled: false' *.md 2>/dev/null || true)
if [ -n "$disabled" ]; then
  echo "⚠ discover-new 有 enabled:false 的规则（晋升后忘开开关？装载了但不生效）："
  echo "$disabled" | sed 's/^/    /'
  divergence=1
fi

if [ "$divergence" -eq 0 ]; then
  echo "✓ 仓库与缓存一致，开关体检通过"
else
  echo
  echo "→ 修：push（仓库为准） / pull（缓存为准）"
fi

# ---- 执行同步 ----
case "$MODE" in
  push)
    echo; echo "== 仓库 -> 缓存 =="
    for pack in baseline skg-spring discover-new; do
      [ -d "$REPO_DIR/rules/$pack" ] || continue
      mkdir -p "$CACHE_DIR/rules/$pack"
      cp "$REPO_DIR/rules/$pack"/*.md "$CACHE_DIR/rules/$pack/"
      echo "  ✓ $pack"
    done
    cp "$REPO_DIR/rules/config.yaml" "$CACHE_DIR/rules/config.yaml"
    cp "$REPO_DIR/rules/README.md" "$CACHE_DIR/rules/README.md"
    echo "  ✓ config.yaml + README.md"
    for dir in skills commands agents; do
      [ -d "$REPO_DIR/$dir" ] || continue
      while IFS= read -r rel; do
        mkdir -p "$CACHE_DIR/$dir/$(dirname "$rel")"
        cp "$REPO_DIR/$dir/$rel" "$CACHE_DIR/$dir/$rel"
      done < <(cd "$REPO_DIR/$dir" && find . -name '*.md' -type f | sed 's|^\./||')
      echo "  ✓ $dir"
    done
    echo "完成。**必须重启 Extension Host 才生效**（Ctrl+Shift+P → Developer: Restart Extension Host；Reload Window 常常不够）。"
    ;;
  pull)
    echo; echo "== 缓存 -> 仓库 =="
    for pack in baseline skg-spring discover-new; do
      [ -d "$CACHE_DIR/rules/$pack" ] || continue
      mkdir -p "$REPO_DIR/rules/$pack"
      cp "$CACHE_DIR/rules/$pack"/*.md "$REPO_DIR/rules/$pack/"
      echo "  ✓ $pack"
    done
    # skills/commands/agents 只回收缓存独有或更新的，不整体覆盖仓库
    # （仓库才是事实来源；这里只捞"改在缓存里忘了入库"的）
    echo "  （skills/commands/agents 不自动 pull——仓库是事实来源。"
    echo "    如确需回收缓存里的改动，先跑 check 看差异再手动 cp）"
    echo "完成。请 git diff 复核后 commit——缓存无版本控制，入库才算数。"
    ;;
  check) ;;
  *) echo "未知模式：$MODE（可用：check | push | pull）"; exit 1 ;;
esac
