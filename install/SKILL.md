---
name: branch-review-guard-installer
version: 0.2.0
description: 把 branch-review-guard 套件（含依赖 api-change-guard、endpoint-perf-review 与可插拔 rules）安装到当前项目。安装前检测已存在的子 skill，按版本覆盖并备份。当用户给出本仓库链接并要求安装到项目时使用。
---

# Branch Review Guard — 安装器

当用户把本仓库链接丢给你并要求"安装到当前项目"时，按本流程执行。你需要能读文件、执行 Git/shell、写文件。

## 0. 约定

- **源仓库**：用户给的链接（本套件仓库）。
- **目标项目**：当前工作区根目录。
- 一切以 `manifest.json` 为准（skills / 版本 / 落地路径 / 依赖 / 规则包）。

## 1. 获取源

```bash
git clone --depth 1 https://github.com/liuzecan-SKG/branch-review-guard <tmp>   # 公开仓，匿名可拉；或下载 raw 文件
```

读 `<tmp>/manifest.json`。若 clone 不可用，从 `https://raw.githubusercontent.com/liuzecan-SKG/branch-review-guard/main/<path>` 逐文件读取 raw。

## 2. 选规则包（决定 SKG 包是否启用）

- 默认只启用 `baseline`（栈无关）。
- 若目标项目是 **Spring Boot + Dubbo + MyBatis + MongoDB + Sa-Token** 同栈（可由 `pom.xml` / 依赖探测），询问或直接启用 `skg-spring`。
- 用户可用 `--rules baseline,skg-spring` 显式指定。最终写入目标项目 `tools/branch-review-guard/rules/config.yaml`。

## 3. 逐 skill 检测 + 决策（满足"安装前判断是否已存在 + 覆盖安装"）

对 `manifest.skills` 里每个 skill：

1. **检测是否已安装**：任一 target（`canonical` 或任一 `mirror`）下存在 `SKILL.md` 即视为已安装。
2. **读已安装版本**：从该 `SKILL.md` frontmatter 的 `version:` 读；无则回退读其 `CHANGELOG.md` 顶部版本；再无标 `legacy/unknown`。
3. **决策**（默认 `overwrite=version-aware`、`backup=true`）：
   - **缺失** → 安装。
   - **已装 == 源版本** → 跳过（幂等）；仅 `--force` 时重装。
   - **已装 != 源版本（升级）** → 先**备份**再**覆盖**。
   - **已装 > 源版本（降级）** → 默认**不覆盖**，仅告警并记录；`--force` 才降级。
   - `--skip-existing`：已存在则完全不动；`--no-backup`：覆盖不备份。
4. **备份**：覆盖前把现有 target 目录/文件移到 `<target>.bak-<yyyyMMdd-HHmmss>/`（或对单文件加同名 `.bak-<ts>`）。

> 子 skill（api-change-guard / endpoint-perf-review）与主 skill 同一套检测/覆盖逻辑，逐个处理。

## 4. 拷贝（canonical → 镜像）

对每个要安装/覆盖的 skill：

1. 把 `source/`（如 `skills/branch-review-guard`）拷到 `targets.canonical`（如 `tools/branch-review-guard`）。
2. 把 canonical 的 `SKILL.md` **同步**到每个 `targets.mirrors`（如 `.cursor/skills/<name>/SKILL.md`、`.claude/skills/<name>/SKILL.md`）。镜像只放 `SKILL.md`（与套件约定一致）。
3. 若该 skill 有 `rule`，把 `cursor-rules/<name>.mdc` 拷到 `.cursor/rules/<name>.mdc`。

## 5. 安装规则包

1. 把源 `rules/`（`README.md`、`config.yaml`、`baseline/`、`skg-spring/` 等）拷到 `tools/branch-review-guard/rules/`。
2. 按第 2 步选择写 `rules/config.yaml` 的 `packs.*.enabled`。

## 6. 接 .gitignore

为每个装了的 skill 追加（去重）：

```gitignore
tools/branch-review-guard/reports/*
!tools/branch-review-guard/reports/.gitkeep
tools/api-change-guard/reports/*
!tools/api-change-guard/reports/.gitkeep
```

## 7. 校验

- 每个 skill 的 canonical `SKILL.md` 与其镜像做内容/哈希一致性校验。
- `rules/config.yaml` 启用的包目录确实存在。
- 主 skill 的 `requires`（api-change-guard、endpoint-perf-review）均已就位，否则告警"该依赖缺失，对应维度会降级"。

## 8. 报告（中文）

输出：装了/覆盖了/跳过了哪些 skill 与版本、启用了哪些规则包、备份位置、未满足的依赖、`.gitignore` 改动。最后给一句话用法：

```text
/branch-review-guard                # 整分支 vs master 综合评审
/branch-review-guard module <模块>  # 缩范围深审
```

## 失败处理

- clone/读文件失败：改用 raw 链接逐文件读取；仍失败则停并报原因。
- 路径冲突/权限：报告冲突项与建议，不强行覆盖未备份的内容。
- 不要在未备份的情况下删除目标项目已有文件。
