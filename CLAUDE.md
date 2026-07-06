# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 这个仓库是什么

一个 **Claude Code 插件 + 单插件 marketplace**（仓库根即 marketplace 根，见 `.claude-plugin/`），功能是提测/上线前对整条功能分支做多维度综合代码评审。**纯 Markdown + Git 命令，没有可执行代码**——没有构建、lint、单测命令；"改代码"就是改 prompt/skill/规则文档。所有文档、commit message、评审报告均为**中文**。

## 架构：一份内核，三种分发形态

内容只在 `skills/` + `rules/` 里编写一次（canonical 源），以三种形态被消费：

1. **Claude Code 插件**（主推）：`.claude-plugin/plugin.json` + `marketplace.json` 声明插件；`commands/*.md` 提供 `/branch-review-guard:review`、`:diff`、`:distill`、`:rule` 四个命令；`agents/bru-*.md` 提供 7 个只读子代理。
2. **安装器**（Cursor/Codex 等其它 Agent）：`install/SKILL.md` 按 `manifest.json` 把 `skills/` 拷到目标项目的 `tools/<name>/`（canonical）+ `.cursor/skills/`、`.claude/skills/` 镜像，做**版本感知覆盖 + 备份**。
3. **裸读**：任何 Agent 直接读 `skills/branch-review-guard/SKILL.md` 执行。

组件关系：

- `skills/branch-review-guard/` — **编排器**（主 skill）：确定范围 → 建上下文 → 自动化先行 → 加载规则包 → 大 diff 分批（强制全覆盖）→ 分维度评审 → 汇总 → 单份中文可发布性报告。维度 prompt 在其 `prompts/`，报告模板在 `templates/`。
- `skills/api-change-guard/`、`skills/endpoint-perf-review/` — 被编排器复用的两个依赖 skill（API 兼容维度、性能维度）。
- `agents/bru-*.md` — 插件形态下的 7 个只读子代理：5 个维度评审（correctness / design / security / tests / observability，按批并行派发）+ 对抗验证怀疑者（`bru-skeptic`，每条 P0/P1 × 3 视角）+ 完整性批评家（`bru-critic`，定稿前 1 个）；不支持子代理的环境自动退化为顺序执行。
- `rules/` — **可插拔规则包**：核心 skill 栈无关，栈特有的"坑"与降噪校准全部外置到这里。`baseline/` 默认开，`skg-spring/` 默认关（本仓库的 `rules/config.yaml` 只是随包分发的默认值；安装器按 `--rules` 写目标项目的 config）。规则文件 schema（frontmatter：`id`/`type: finding|calibration`/`dimension`/`severity`/`applies_to`）见 `rules/README.md`。
- `cursor-rules/*.mdc` — Cursor 专属的可选 auto-attach 提醒，其它形态忽略。

## 修改时的关键纪律

### 版本必须四处同步

发版时以下位置的版本号**必须一起改**，否则安装器的版本感知覆盖会失灵（0.2.5 就修过这种脱节）：

- `.claude-plugin/plugin.json` 的 `version`
- `manifest.json` 的 `suite.version`
- 受影响 skill 的 `skills/<name>/SKILL.md` frontmatter `version:`
- `skills/branch-review-guard/CHANGELOG.md` 加一节（本仓库的变更史与决策记录都在这里，不在 README）

### "自主执行"指令在四处冗余，改一处要同步四处

评审流程"被触发后一气呵成、中途不回问用户"的指令同时写在 `skills/branch-review-guard/SKILL.md`（工作流程节）、`skills/branch-review-guard/prompts/orchestrate-branch-review.md`、`commands/review.md`、`commands/diff.md`。0.2.9 修复的 bug 就是几处措辞不一致导致 agent 停在"建立上下文"等用户输入。改任何一处的流程措辞，检查其余几处。

### 其它约定

- 插件命令文件名 = 命令动词：`commands/review.md` → `/branch-review-guard:review`（`<插件名>:<文件名>` 命名空间）。新增命令沿用 `<verb>.md` 命名。
- 编排器的**诚实边界**是产品核心卖点：运行时维度（性能/并发/迁移）只允许输出"需运行时验证项"，禁止写出"已验证通过"。改 prompt 时不要削弱这条。
- `manifest.json` 是安装器的唯一事实来源（skills 清单、落地路径、依赖、规则包）；增删 skill 或改落地路径要先改它。
- 报告落地路径是插件感知的双路径逻辑：优先 `tools/branch-review-guard/reports/`（安装器形态），否则项目根 `branch-review-reports/`。这段逻辑在多个 SKILL.md/README 中重复出现，改动需全局搜索同步。

## 验证方式（无自动化测试）

- 插件改动生效：VSCode 中 `Ctrl+Shift+P` → **Developer: Restart Extension Host**（`Reload Window` 常常不够，`/reload-plugins` 不可用）。
- 查本机已安装插件版本：
  ```bash
  node -e "const d=require(require('os').homedir()+'/.claude/plugins/installed_plugins.json');for(const[k,v]of Object.entries(d.plugins))console.log(k,v[0].version)"
  ```
- 功能验证 = 在一个真实 Git 项目里跑 `/branch-review-guard:review`（或其 `diff`/`recent <N>`/`module <名>` 模式），检查报告的覆盖率声明与结论格式。
