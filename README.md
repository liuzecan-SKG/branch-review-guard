# Branch Review Guard

提测/上线前对**整条功能分支**（相对主分支的累计变更）做一次多维度综合代码评审的 **Agent Skill 套件**。它给出可发布性结论 + 按优先级排序的发现 + must-fix 清单，产出一份可存档报告。

与 PR 阶段的轻量评审（Bugbot / CodeRabbit / Greptile 等）**互补**：那些擅长单 PR 增量、低延迟；本套件专攻"整分支一次性、强制全覆盖、诚实标注运行时边界、给可发布性裁决"。

## 三种安装方式（先看这张表）

| 方式 | 怎么装 | 拷文件进项目? | 版本感知 / 覆盖 | 一键启停 | 适合 |
|---|---|---|---|---|---|
| **① 插件路径** | `/plugins`(VSCode 扩展 UI) 或 `/plugin`(CLI) 加 marketplace 并安装 | **否**（插件区加载） | ✗ 无；项目里旧本地副本会**遮蔽**插件，需**手动删** | ✅ `/plugins` 开关 | Claude Code 用户，要一键启停/版本/部门复用 |
| **② 安装器路径** | 让 Agent 读 `install/SKILL.md`（`manifest.json` 驱动） | **是**（`tools/<name>/`、`.claude`/`.cursor` 镜像、`rules/`） | ✅ **版本感知覆盖 + 自动备份** | ✗（删文件） | 任意 Agent（Cursor / Codex / Cline）、要入库随项目走 |
| **③ 手动复制** | `git clone` 后 `cp` 到约定位置 | **是** | ✗ 自己管 | ✗ | 离线 / 完全手控 |

> 关键区别：**只有①是"插件"**——不拷文件、靠插件机制加载、可一键启停/版本/复用，但旧本地副本会**遮蔽**它（需先删，见 [升级与迁移](#升级与迁移项目里已有旧-skill-副本时)）；**②/③把文件拷进项目**，其中**只有②（安装器）做版本感知覆盖+备份**，③纯手工无版本逻辑。

## 安装方式①：Claude Code 原生插件（一键启停 / 版本 / 部门复用，推荐）

本仓库同时是一个 **Claude Code 插件 + 单插件 marketplace**（`.claude-plugin/`）。

- **VSCode 扩展**：输入 `/plugins` 打开图形界面 → Marketplaces 标签填 `liuzecan-SKG/branch-review-guard` 点 Add → Plugins 标签 Install。（扩展不支持 `/plugin marketplace add` 这类 CLI 子命令。）
- **CLI（终端 `claude`）**：三步命令：

```text
/plugin marketplace add liuzecan-SKG/branch-review-guard
/plugin install branch-review-guard@branch-review-guard
/branch-review-guard
```

- **一键启停**：`/plugin` 启用/禁用整套，连带 3 个 skill、5 个维度子代理、`/branch-review-guard` 命令一起上下线，无残留。
- **装好后建议立即开启 auto-update**（取代手动更新，详见下方 [更新与卸载](#更新与卸载)）：`/plugins` → Marketplaces → 选本插件 → Enable auto-update。此后每次启动自动对齐最新版。
- **版本迭代**：`.claude-plugin/plugin.json` 的 `version`(SemVer) 控制；配合 auto-update 自动下发。
- **部门复用**：同事执行上面 `marketplace add` 即可接入，取代手工拷目录。
- **维度子代理**：插件预置 `bru-correctness` / `bru-design` / `bru-security` / `bru-tests` / `bru-observability` 五个只读子代理，编排器按批并行派发、上下文隔离（不支持子代理的环境自动回退顺序多轮）。
- 安装在用户级；要随项目入库、随分支共享给同事，走 `--scope project`（写入 `.claude/settings.json`）或在 `.claude/settings.json` 用 `extraKnownMarketplaces` + `enabledPlugins` 声明。

## 安装方式②：安装器路径（任意 Agent 通用，版本感知覆盖 + 备份）

任意能读文件 + 跑 Git 的 Agent（Cursor / Codex / Cline 等）都能用，无需任何 IDE 自带 `/review` 命令。本仓公开，匿名即可拉取。把下面这句丢给 Agent，它会**按 `manifest.json` 把文件拷进项目，已存在则版本感知覆盖并先备份**：

> 读取 `https://raw.githubusercontent.com/liuzecan-SKG/branch-review-guard/main/install/SKILL.md` 并按其流程把 branch-review-guard 套件安装到当前项目；按其指引 `git clone https://github.com/liuzecan-SKG/branch-review-guard` 获取完整文件树；检测已存在的 api-change-guard、endpoint-perf-review 按版本覆盖并先备份；若本项目是 Spring/Dubbo/MyBatis/Mongo 同栈，启用 `skg-spring` 规则包，否则只启用 `baseline`；最后给安装报告。

这条**有版本感知覆盖**：升级则备份+覆盖、降级默认不覆盖（需 `--force`）、同版本跳过；备份在 `<target>.bak-<时间戳>/`。详见 [INSTALL.md](INSTALL.md)。

## 安装方式③：手动复制 / 只想用不想装

- **手动复制**：`git clone` 后按 [INSTALL.md 的「方式二：手动安装」](INSTALL.md) 把 `skills/<name>`、`rules/` `cp` 到项目约定位置（无版本逻辑，自行先备份）。
- **只想用、不想装**：让 Agent 直接读 `skills/branch-review-guard/SKILL.md`（它会复用 `skills/api-change-guard`、`skills/endpoint-perf-review`、`rules/`），不落地任何文件。
- **跨 Agent 说明**见 [AGENTS.md](AGENTS.md)。Cursor 的 `.mdc` 与 `.cursor`/`.claude` 镜像是**可选增强**，不装也能用。

> 三种方式**共存互不影响**：Claude Code 用户走方式①插件；Cursor / Codex 等走方式②安装器或③手动。同一份 `skills/` + `rules/` 内核，多种封装出口。

## 升级与迁移（项目里已有旧 skill 副本时）

采纳本套件分两种场景，**插件路径与通用安装器路径行为不同**，务必区分：

### 场景一：全新项目（从未装过这些 skill）

直接按上面任一方式安装即可，无冲突。

### 场景二：项目里已存在旧的 skill 目录（曾手工拷过 / 装过早期版本）

| 安装路径 | 旧副本的处理 | 你要做什么 |
|---|---|---|
| **插件（`/plugins`）** | 插件**不拷文件进项目、不"覆盖"旧副本**；项目里的旧 `tools/<name>`、`.claude/skills/<name>`、`.cursor/skills/<name>` 会**遮蔽**插件（`/branch-review-guard` 命中旧版而非插件最新版）。 | **先删除旧副本**，插件自带最新版顶上（见下方清单）。 |
| **通用安装器（`install/SKILL.md`）** | 安装器以各 `SKILL.md` 的 `version:` 做**版本感知覆盖 + 自动备份**（`<target>.bak-<时间戳>/`）。 | 直接重跑安装器即可，旧副本被最新版覆盖。 |

**插件路径下需删除的旧副本**（仅本套件三个 skill + 其 Cursor `.mdc`；`design-to-api` 等其它 skill 不动）：

```text
.claude/skills/branch-review-guard   .claude/skills/api-change-guard
.cursor/skills/branch-review-guard   .cursor/skills/api-change-guard   .cursor/skills/endpoint-perf-review
.cursor/rules/branch-review-guard.mdc   .cursor/rules/endpoint-perf-review.mdc
tools/branch-review-guard   tools/api-change-guard   (及随其安装的 tools/branch-review-guard/rules)
```

> 也可把这句丢给 Agent 自动迁移：“删除本项目中 branch-review-guard / api-change-guard / endpoint-perf-review 这三个 skill 的旧本地副本（`tools/`、`.claude/skills/`、`.cursor/skills/`、`.cursor/rules/*.mdc`），保留其它 skill，改由已安装的 branch-review-guard 插件提供最新版。”
>
> 删除后在 `/plugins` 里对 `branch-review-guard` 执行 Update/Refresh，确保用的是插件最新版。**插件本身无法删除消费方项目里的文件**（这是插件机制限制），故场景二的清理须由使用方执行。

## 更新与卸载

更新**不碰项目文件**（删文件只是首次迁移的一次性动作，见上节）。

### 更新：开启 auto-update（推荐，取代手动更新）

本套件**以 auto-update 作为标准更新方式**——开启后每次 Claude Code 启动会自动 `git pull` 最新版并**激活**，免去"刷新 → 激活"两步、也规避当前 UI 看不到版本号的困扰。**装好后建议立即开启，之后无需任何手动更新操作。**

开启方式（任一）：

- **VSCode 扩展**：`/plugins` → **Marketplaces** 选项卡 → 选 `branch-review-guard` → **Enable auto-update**，然后 `Developer: Reload Window`。
- **`.claude/settings.json`（推荐，可随分支共享给同事）**：marketplace 条目加 `"autoUpdate": true`：

```json
{
  "extraKnownMarketplaces": {
    "branch-review-guard": {
      "source": { "source": "github", "repo": "liuzecan-SKG/branch-review-guard" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": { "branch-review-guard@branch-review-guard": true }
}
```

> 开启后，维护方每次发布（bump 版本）你**下次启动即自动拿到**，无需手动刷新/激活。

### 手动更新（仅在未开 auto-update 时的兜底）

| 环境 | 操作 |
|---|---|
| **VSCode 扩展** | `/plugins` → **Marketplaces** 对 marketplace 点**刷新**（git pull 最新进缓存）→ 回 **Plugins** 对插件点 **Update/Install** 激活 |
| **CLI** | `/plugin marketplace update branch-review-guard` 然后 `/plugin install branch-review-guard@branch-review-guard` |

> ⚠️ **故障排查 ·「刷新后没更新」**：**刷新 marketplace ≠ 激活已安装插件**。刷新只把最新版 `git pull` 进缓存（`~/.claude/plugins/cache`），而激活指针（`installed_plugins.json`）需由"更新/重装"或 auto-update 切换。当前 UI 基本不显示版本号，若刷新后看不到更新按钮：**卸载后重装**，或直接开 **auto-update** 一劳永逸。

> ⚠️ **维护者必读 · 版本钉住规则**：`plugin.json` 设了 `version` 后插件被**钉死在该版本字符串**——只 push 新 commit、不改 `version`，消费方（即便开了 auto-update）也拿不到更新。因此**每次发布必须 bump `plugin.json` 与 `manifest.json` 的 `version`**（与 `CHANGELOG.md` 同步）。替代：删 `version` 用 commit SHA 当版本，每 commit 自动下发（失去 SemVer 语义）。本套件保留 `version` + 每次发布 bump。

### 禁用 / 卸载（干净，无项目残留）

| 操作 | VSCode 扩展 | CLI | 效果 |
|---|---|---|---|
| **禁用**（保留安装） | Plugins → 详情 → **Disable** | `/plugin disable branch-review-guard@branch-review-guard` | 停用，不删文件，可随时 Enable |
| **完全卸载** | Plugins → 详情 → **Uninstall** | `/plugin uninstall branch-review-guard@branch-review-guard` | 移除插件；**项目里无残留**（插件仅缓存于 `~/.claude/plugins/cache`，从不往项目拷文件） |

- 编辑 `.claude/settings.json`：`enabledPlugins` 的 `true/false` 只控制**启用/禁用**，不等于卸载；从 `extraKnownMarketplaces` 移除该 marketplace 的最后一个引用会**连带卸载**其插件。
- 彻底清缓存（排障用）：`rm -rf ~/.claude/plugins/cache`。

## 它包含什么

- **branch-review-guard**（主 skill / 编排器）：分批全覆盖、按风险聚焦、L1/L2/L3 护栏、可发布性报告。
- **api-change-guard**（依赖）：API/兼容性/影响范围/回归分析。
- **endpoint-perf-review**（依赖）：单接口性能调用链复盘。
- **可插拔规则机制 `rules/`**：核心栈无关；项目/技术栈特有知识做成可开关的规则包。
  - `rules/baseline/`：默认开启，栈无关。
  - `rules/skg-spring/`：可选包，针对 Spring Boot + Dubbo + MyBatis + MongoDB(自研事务) + Sa-Token + RocketMQ。

## 设计原则

- **自包含、零运行时依赖、可移植**：纯 Agent 规则 + Git 命令，可在任意能读文件+跑 Git 的 Agent / CI 中运行。
- **强制全覆盖 + 覆盖率声明**：不因体量截断；报告显式声明覆盖率与未覆盖。
- **诚实边界**：运行时维度（性能 p99 / 并发 / 迁移真实表现）只输出"需运行时验证项"，绝不下"已验证通过"。
- **复用而非重造**：API/兼容走 api-change-guard，性能走 endpoint-perf-review。

## 仓库结构

```text
branch-review-guard/
  .claude-plugin/            # 【Claude Code 插件层】
    plugin.json              #   插件清单（name/version/...，组件按约定自动发现）
    marketplace.json         #   单插件 marketplace（source: "./"）
  commands/                  #   /branch-review-guard slash 命令
    branch-review-guard.md
  agents/                    #   5 个只读维度子代理（编排器按批并行派发）
    bru-correctness.md  bru-design.md  bru-security.md  bru-tests.md  bru-observability.md
  AGENTS.md                  # 跨 Agent 通用入口/发现（任意 agent 读 skills/<name>/SKILL.md）
  README.md  INSTALL.md  LICENSE  manifest.json
  install/SKILL.md            # 安装器（agent 读它执行安装，供非 Claude-Code Agent）
  skills/                     # 三个 skill 的 canonical 源（插件 + 通用安装器共享同一份）
    branch-review-guard/  api-change-guard/  endpoint-perf-review/
  rules/                     # 可插拔规则包
    README.md  config.yaml  baseline/  skg-spring/
  cursor-rules/              # 【可选】Cursor 专属 .mdc 自动提醒（非 Cursor agent 可忽略）
    branch-review-guard.mdc  endpoint-perf-review.mdc
```

## 使用教程（覆盖全部场景）

安装后用 `/branch-review-guard [模式] [选项]`。**留空 = `branch` 全量模式**（提测/上线卡点，最常用）。

### 四种模式

```text
/branch-review-guard                          # branch：整分支相对 master 累计变更，全维度（默认）
/branch-review-guard branch --base develop    # 改对比基线（缺省自动探测 master/main）
/branch-review-guard module <模块名>           # 只深审某模块（缩范围、提精度），如 module skg-health-global-user
/branch-review-guard diff                     # 仅未提交变更（边写边查，最快，迭代期用）
/branch-review-guard recent 3                 # 最近 N 个提交
```

### 选项

```text
--base <分支>                # 指定对比基线（默认自动探测 origin/master → origin/main）
--dimensions <逗号分隔>      # 只跑部分维度，缺省=全部
```

`--dimensions` 取值：`bug`（正确性）`design`（设计/质量）`security`（安全）`test`（测试）`api`（兼容/影响/回归，复用 api-change-guard）`perf`（性能，复用 endpoint-perf-review）`observability`（可观测/运维/i18n）。例：

```text
/branch-review-guard branch --dimensions bug,security        # 只看正确性 + 安全
/branch-review-guard module skg-health-global-user --dimensions api,perf
```

### 典型用法时机

| 场景 | 命令 | 说明 |
|---|---|---|
| 提测/上线前卡点 | `/branch-review-guard` | 整分支全覆盖，出可发布性裁决报告 |
| 迭代期边写边查 | `/branch-review-guard diff` | 只看工作区改动，快 |
| 聚焦某模块深审 | `/branch-review-guard module <名>` | 缩范围换深度 |
| 复核最近几个提交 | `/branch-review-guard recent <N>` | 提交后自查 |
| 只关心某几维 | `... --dimensions bug,security` | 省时 |

### 它会做什么

1. 建立上下文（读 `*_DESIGN.md`/`*_CONTRACT.md`/commit message）→ 自动化先行(L1) → 加载启用的 `rules/` 规则包 → 估规模分批（大 diff 强制全覆盖）。
2. **Claude Code 插件形态**：按批并行派发 5 个只读维度子代理（`bru-correctness`/`bru-design`/`bru-security`/`bru-tests`/`bru-observability`），上下文隔离；不支持子代理的环境自动顺序多轮。
3. 复用 `api-change-guard`（兼容/影响/回归）与 `endpoint-perf-review`（仅高风险接口性能）。
4. 汇总去重、统一定级（P0/P1/P2/Nit），产出**一份中文报告**：先给可发布性结论 + Top 风险，再分维度发现、阻塞清单、覆盖率声明。运行时维度只给"需运行时验证项"。

报告落地在 `tools/branch-review-guard/reports/`（已 `.gitignore`），命名 `branch-review-guard-<mode>-<shortSha>-<timestamp>.md`。

### 非 slash 环境 / 命令未识别

直接对 Agent 说："读取 branch-review-guard 的 SKILL.md（`skills/branch-review-guard/SKILL.md` 或安装后的 `tools/branch-review-guard/SKILL.md`）并按其流程对当前分支相对 master 做提测前综合评审。"

## 为自己的技术栈加规则包

复制 `rules/skg-spring/` 为 `rules/<your-stack>/`，按 `rules/README.md` 的 schema 写规则，在 `rules/config.yaml` 启用即可。核心 skill 无需改动。

## 许可

见 [LICENSE](LICENSE)。
