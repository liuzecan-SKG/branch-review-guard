# AGENTS.md — branch-review-guard 套件

本仓库是一个**可移植、栈无关**的 Agent Skill 套件：提测/上线前对整条功能分支做多维度综合代码评审。核心是纯 markdown + Git 命令，**不绑定任何特定 IDE/Agent**，任何能读文件并执行 Git 的 Agent 都能用。

## 任意 Agent：怎么用

- **直接使用某个 skill**：读取 `skills/<name>/SKILL.md` 并按其流程执行。入口是 `skills/branch-review-guard/SKILL.md`（它会复用 `skills/api-change-guard`、`skills/endpoint-perf-review` 与 `rules/`）。
- **安装到某个项目**：读取 `install/SKILL.md` 并按其流程执行（以 `manifest.json` 为准：检测已装版本 → 按版本覆盖+备份 → 落地）。

不需要任何 IDE 自带的 `/review` 类命令；不需要 Python/Node。

## 套件内容

- `skills/branch-review-guard/` — 主 skill（评审编排器）：整分支累计评审、大 diff 强制全覆盖、P0/P1 对抗性验证 + 完整性核查、L1/L2/L3 护栏、可发布性裁决报告；配套 `distill`/`rule` 反馈闭环（报告 →（按代码实例聚类 / 遗留项分诊 / 手动录入）→ 候选规则草稿）。
- `skills/design-panel/` — 设计侧姊妹 skill（设计编排器）：需求方案设计阶段多视角设计对比（独立成案 → 对抗质证 → 裁判嫁接），产出对比表 + 推荐方案 + 精炼设计稿（移入 `docs/` 供 `:review` 建立上下文）；`requires: ["branch-review-guard"]`（共享 `rules/` 与 `reports/`）。
- `skills/api-change-guard/` — 依赖：API/兼容/影响/回归分析。
- `skills/endpoint-perf-review/` — 依赖：单接口性能调用链复盘。
- `rules/` — 可插拔规则包：`baseline/`（默认开，栈无关）+ `skg-spring/`（默认关，Spring/Dubbo/MyBatis/Mongo 栈）；schema 见 `rules/README.md`。

## 各 Agent 的安装位置（差异在“装哪”，不在 skill 本身）

| Agent | 读取位置 | 备注 |
|---|---|---|
| 任意 / 通用 | `tools/<name>/SKILL.md`（或直接 `skills/<name>/SKILL.md`） | canonical 正本，最通用 |
| Cursor | `.cursor/skills/<name>/SKILL.md` + `.cursor/rules/*.mdc` | `.mdc` 是**可选**的自动提醒（来自 `cursor-rules/`） |
| Claude Code（插件，推荐） | VSCode 扩展：`/plugins` UI 加 marketplace `liuzecan-SKG/branch-review-guard` 并 Install；CLI：`/plugin marketplace add ...` → `/plugin install branch-review-guard@branch-review-guard` | 经 `.claude-plugin/` 一键装全套（4 skill + 10 只读子代理 + `/branch-review-guard:review`、`:diff`、`:distill`、`:rule`、`:design` 命令），支持启停/版本/复用；安装与更新详见 README |
| Claude Code（手工镜像） | `.claude/skills/<name>/SKILL.md` | 不用插件时的 SKILL.md 镜像 |

- `cursor-rules/*.mdc` 是 **Cursor 专属的可选增强**（auto-attach 提醒），在其它 Agent 上被忽略、不影响功能；不装也能用。
- installer 默认会把 canonical + 各镜像 + `.mdc` 都装上；只想要通用形态时，装 `tools/<name>/`（或让 Agent 直接读 `skills/<name>/SKILL.md`）即可。

## 给自己的技术栈扩展

复制 `rules/skg-spring/` 为 `rules/<your-stack>/`，按 `rules/README.md` 的 schema 写规则，在 `rules/config.yaml` 启用。核心 skill 无需改动。
