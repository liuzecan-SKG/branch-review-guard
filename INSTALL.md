# 安装指南

本套件是纯 markdown 的 Agent Skill，**栈无关、不绑定任何 IDE/Agent**。"安装" = 把文件拷到目标项目的约定位置。跨 Agent 说明见 [AGENTS.md](AGENTS.md)。两种方式：

## 方式一：交给 Agent 自动安装（推荐，任意 Agent 通用）

把这句丢给任意能读文件 + 跑 Git 的 Agent（Cursor / Claude Code / Codex CLI / Cline 等）：

> 读取 `https://raw.githubusercontent.com/liuzecan-SKG/branch-review-guard/main/install/SKILL.md` 并按其流程把 branch-review-guard 套件安装到当前项目（按其指引 `git clone https://github.com/liuzecan-SKG/branch-review-guard` 取完整文件树）；检测是否已存在 api-change-guard、endpoint-perf-review，按版本覆盖并先备份；若本项目是 Spring/Dubbo/MyBatis/Mongo 同栈，启用 `skg-spring` 规则包，否则只启用 `baseline`；最后给安装报告。

Agent 会：拉取源 → 读 `manifest.json` → 逐 skill 检测已装版本 → 按版本覆盖（先备份）→ 拷到 `tools/<name>/`（canonical，通用）→ 安装 `rules/` 并写 `config.yaml` → 接 `.gitignore` → 校验 → 报告。

> **可选（按 Agent）**：Cursor 额外装 `.cursor/skills/` 镜像 + `.cursor/rules/*.mdc`（自动提醒）；Claude Code 额外装 `.claude/skills/` 镜像。非 Cursor/Claude 的 Agent 只用 `tools/<name>/SKILL.md` 即可，`.mdc` 与镜像可跳过。

> 本仓公开：匿名即可 `git clone` / 读取 raw，无需任何凭据。

可选参数（在指令里说明）：`--rules baseline,skg-spring`、`--force`（同版本/降级也覆盖）、`--skip-existing`、`--no-backup`。

## 方式二：手动安装

```bash
git clone --depth 1 <repo-url> brg && cd brg
# 对 manifest.json 里每个 skill：source -> targets.canonical，再把 SKILL.md 同步到 mirrors
cp -r skills/branch-review-guard   <project>/tools/branch-review-guard
cp -r skills/api-change-guard      <project>/tools/api-change-guard
cp -r skills/endpoint-perf-review  <project>/tools/endpoint-perf-review
cp -r rules                        <project>/tools/branch-review-guard/rules
# （可选，仅 Cursor/Claude）镜像每个 skill 的 SKILL.md
mkdir -p <project>/.cursor/skills/branch-review-guard <project>/.claude/skills/branch-review-guard
cp tools/branch-review-guard/SKILL.md <project>/.cursor/skills/branch-review-guard/SKILL.md
cp tools/branch-review-guard/SKILL.md <project>/.claude/skills/branch-review-guard/SKILL.md
# （可选，仅 Cursor）自动提醒规则：
cp cursor-rules/branch-review-guard.mdc  <project>/.cursor/rules/branch-review-guard.mdc
cp cursor-rules/endpoint-perf-review.mdc <project>/.cursor/rules/endpoint-perf-review.mdc
```

> 通用 Agent 只需上面的 `tools/<name>/` canonical；`.cursor`/`.claude` 镜像与 `.mdc` 是按 Agent 的可选增强。

然后编辑 `<project>/tools/branch-review-guard/rules/config.yaml`，按需把 `skg-spring` 设为 `enabled: true`。

## 覆盖安装说明

- 安装器以各 skill `SKILL.md` 的 `version:` 判断已装版本，按"升级则备份+覆盖、降级默认不覆盖（需 --force）、同版本跳过"处理。
- 备份位置：`<target>.bak-<时间戳>/`。手动安装请自行先备份已存在的同名目录。
- **Claude Code 插件路径不同**：插件不拷文件进项目、不覆盖旧副本；项目里已有的旧 skill 目录会**遮蔽**插件，需**先删除**旧副本（清单与迁移指引见 [README 的"升级与迁移"](README.md#升级与迁移项目里已有旧-skill-副本时)）。版本感知覆盖仅适用于本安装器路径。

## 前置

- 目标项目是 Git 仓库。
- Agent 能读文件、执行 Git/shell、写文件。
- 无需 Python / Node，无需联网（除拉取源仓库）。

## 验证安装

```text
/branch-review-guard
```
或（任意 Agent）："读取 branch-review-guard 的 SKILL.md（安装后的 `tools/branch-review-guard/SKILL.md`）并对当前分支相对 master 做提测前综合评审。"
