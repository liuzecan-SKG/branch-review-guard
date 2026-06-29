# Branch Review Guard

提测/上线前对**整条功能分支**（相对主分支的累计变更）做一次多维度综合代码评审的 **Agent Skill 套件**。它给出可发布性结论 + 按优先级排序的发现 + must-fix 清单，产出一份可存档报告。

与 PR 阶段的轻量评审（Bugbot / CodeRabbit / Greptile 等）**互补**：那些擅长单 PR 增量、低延迟；本套件专攻"整分支一次性、强制全覆盖、诚实标注运行时边界、给可发布性裁决"。

## 安装方式一：Claude Code 原生插件（一键启停 / 版本 / 部门复用，推荐）

本仓库同时是一个 **Claude Code 插件 + 单插件 marketplace**（`.claude-plugin/`）。在 Claude Code 里三步接入：

```text
/plugin marketplace add liuzecan-SKG/branch-review-guard
/plugin install branch-review-guard@branch-review-guard
/branch-review-guard
```

- **一键启停**：`/plugin` 启用/禁用整套，连带 3 个 skill、5 个维度子代理、`/branch-review-guard` 命令一起上下线，无残留。
- **版本迭代**：`.claude-plugin/plugin.json` 的 `version`(SemVer) 控制；`/plugin update` 升级。
- **部门复用**：同事执行上面 `marketplace add` 即可接入，取代手工拷目录。
- **维度子代理**：插件预置 `bru-correctness` / `bru-design` / `bru-security` / `bru-tests` / `bru-observability` 五个只读子代理，编排器按批并行派发、上下文隔离（不支持子代理的环境自动回退顺序多轮）。
- 安装在用户级；要随项目入库走 `--scope project`。

> 插件层与下面的「任意 Agent 通用」安装方式**共存互不影响**：Claude Code 用户走插件，Cursor / Codex / 其它 Agent 仍走 `manifest.json` 安装器或直接读 `skills/<name>/SKILL.md`。同一份 `skills/` + `rules/` 内核，多种封装出口。

## 安装方式二：任意 Agent 通用（栈无关，Cursor / Codex / Cline 等）

任意能读文件 + 跑 Git 的 Agent 都能用，无需任何 IDE 自带 `/review` 命令。本仓公开，匿名即可拉取。把下面这句丢给 Agent：

> 读取 `https://raw.githubusercontent.com/liuzecan-SKG/branch-review-guard/main/install/SKILL.md` 并按其流程把 branch-review-guard 套件安装到当前项目；按其指引 `git clone https://github.com/liuzecan-SKG/branch-review-guard` 获取完整文件树；检测已存在的 api-change-guard、endpoint-perf-review 按版本覆盖并先备份；若本项目是 Spring/Dubbo/MyBatis/Mongo 同栈，启用 `skg-spring` 规则包，否则只启用 `baseline`；最后给安装报告。

- **只想用、不想装**：让 Agent 直接读 `skills/branch-review-guard/SKILL.md`（它会复用 `skills/api-change-guard`、`skills/endpoint-perf-review`、`rules/`）。
- **跨 Agent 说明**见 [AGENTS.md](AGENTS.md)；安装细节见 [INSTALL.md](INSTALL.md)。Cursor 的 `.mdc` 与 `.cursor`/`.claude` 镜像是**可选增强**，不装也能用。

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
