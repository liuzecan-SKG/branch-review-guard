# Branch Review Guard

提测/上线前对**整条功能分支**（相对主分支的累计变更）做一次多维度综合代码评审的 **Agent Skill 套件**。它给出可发布性结论 + 按优先级排序的发现 + must-fix 清单，产出一份可存档报告。

与 PR 阶段的轻量评审（Bugbot / CodeRabbit / Greptile 等）**互补**：那些擅长单 PR 增量、低延迟；本套件专攻"整分支一次性、强制全覆盖、诚实标注运行时边界、给可发布性裁决"。

## 安装（任意 Agent 通用）

任意能读文件 + 跑 Git 的 Agent（Cursor / Claude Code / Codex CLI / Cline 等）都能用，无需任何 IDE 自带 `/review` 命令。把下面这句丢给 Agent：

> clone 本仓库到临时目录，读取其中 `install/SKILL.md` 并按流程把 branch-review-guard 套件安装到当前项目；检测已存在的 api-change-guard、endpoint-perf-review 按版本覆盖并先备份；若本项目是 Spring/Dubbo/MyBatis/Mongo 同栈，启用 `skg-spring` 规则包，否则只启用 `baseline`；最后给安装报告。

- **私有仓**：安装者需对本仓有访问权限（用自己的 Git 凭据 clone；匿名 raw 链接拉不到）。
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
  AGENTS.md                  # 跨 Agent 通用入口/发现（任意 agent 读 skills/<name>/SKILL.md）
  README.md  INSTALL.md  LICENSE  manifest.json
  install/SKILL.md            # 安装器（agent 读它执行安装）
  skills/                     # 三个 skill 的 canonical 源（最通用，任意 agent 直接读）
    branch-review-guard/  api-change-guard/  endpoint-perf-review/
  rules/                     # 可插拔规则包
    README.md  config.yaml  baseline/  skg-spring/
  cursor-rules/              # 【可选】Cursor 专属 .mdc 自动提醒（非 Cursor agent 可忽略）
    branch-review-guard.mdc  endpoint-perf-review.mdc
```

## 用法（安装后）

```text
/branch-review-guard                       # 默认：整分支 vs master 全维度评审
/branch-review-guard module <模块名>        # 缩范围深审
/branch-review-guard branch --dimensions bug,security
/branch-review-guard diff                   # 仅未提交变更
```

slash 未识别（或非 Cursor agent）时直接说："读取 branch-review-guard 的 SKILL.md（`skills/branch-review-guard/SKILL.md` 或安装后的 `tools/branch-review-guard/SKILL.md`）并按其流程对当前分支相对 master 做提测前综合评审。"

## 为自己的技术栈加规则包

复制 `rules/skg-spring/` 为 `rules/<your-stack>/`，按 `rules/README.md` 的 schema 写规则，在 `rules/config.yaml` 启用即可。核心 skill 无需改动。

## 许可

见 [LICENSE](LICENSE)。
