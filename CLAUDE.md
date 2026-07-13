# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 这个仓库是什么

一个 **Claude Code 插件 + 单插件 marketplace**（仓库根即 marketplace 根，见 `.claude-plugin/`），功能是提测/上线前对整条功能分支做多维度综合代码评审。**纯 Markdown + Git 命令，没有可执行代码**——没有构建、lint、单测命令；"改代码"就是改 prompt/skill/规则文档。所有文档、commit message、评审报告均为**中文**。

## 架构：一份内核，三种分发形态

内容只在 `skills/` + `rules/` 里编写一次（canonical 源），以三种形态被消费：

1. **Claude Code 插件**（主推）：`.claude-plugin/plugin.json` + `marketplace.json` 声明插件；`commands/*.md` 提供 `/branch-review-guard:review`、`:diff`、`:distill`、`:rule`、`:design` 命令；`agents/bru-*.md` + `agents/dsp-*.md` 提供 11 个只读子代理（评审侧 8 + 设计侧 3）。
2. **安装器**（Cursor/Codex 等其它 Agent）：`install/SKILL.md` 按 `manifest.json` 把 `skills/` 拷到目标项目的 `tools/<name>/`（canonical）+ `.cursor/skills/`、`.claude/skills/` 镜像，做**版本感知覆盖 + 备份**。
3. **裸读**：任何 Agent 直接读 `skills/branch-review-guard/SKILL.md` 执行。

组件关系：

- `skills/branch-review-guard/` — **评审编排器**（主 skill）：确定范围 → 建上下文 → 自动化先行 → 加载规则包 → 大 diff 分批（强制全覆盖）→ 分维度评审 → 汇总 → 单份中文可发布性报告。维度 prompt 在其 `prompts/`，报告模板在 `templates/`。
- `skills/design-panel/` — **设计编排器**（设计侧姊妹 skill）：需求方案设计阶段并行派 N 个互不可见的设计代理独立成案 → 对每案承重论断派怀疑者对抗质证 → 裁判打分嫁接，产出对比表 + 推荐方案 + 精炼设计稿（移入 `docs/` 供 `:review` 建立上下文）。`requires: ["branch-review-guard"]`，共享 `rules/` 与 `reports/` 目录；自身设计文档 `DESIGN.md` 记录用「设计擂台」模式产出的过程留证。
- `skills/api-change-guard/`、`skills/endpoint-perf-review/` — 被编排器复用的两个依赖 skill（API 兼容维度、性能维度）。
- `agents/bru-*.md` + `agents/dsp-*.md` — 插件形态下的 11 个只读子代理：**评审侧 8 个** `bru-*`（6 个维度评审 correctness / design / security / tests / observability / business-invariant，按批并行派发 + 对抗验证怀疑者 `bru-skeptic`——每条 P0/P1 × 3 视角降误报 + 对"正例/零发现"× 第 4 视角假设证伪捞漏报 + 完整性批评家 `bru-critic`，定稿前 1 个）；**设计侧 3 个** `dsp-*`（`dsp-designer` 设计代理按视角并行 N 实例 + `dsp-skeptic` 每方案 1 个质证 + `dsp-judge` 裁判定稿前 1 个）。**所有子代理的只读靠 frontmatter `tools: Read, Grep, Glob, Bash` 白名单保证**（不是 prompt 里的一句话）；不支持子代理的环境自动退化为顺序执行。
- `rules/` — **可插拔规则包**：核心 skill 栈无关，栈特有的"坑"与降噪校准全部外置到这里。`baseline/` 默认开，`skg-spring/` 默认关（本仓库的 `rules/config.yaml` 只是随包分发的默认值；安装器按 `--rules` 写目标项目的 config）。规则文件 schema（frontmatter：`id`/`type: finding|calibration`/`dimension`/`severity`/`applies_to`）见 `rules/README.md`。
- `cursor-rules/*.mdc` — Cursor 专属的可选 auto-attach 提醒，其它形态忽略。

## 修改时的关键纪律

### 版本必须四处同步

发版时以下位置的版本号**必须一起改**，否则安装器的版本感知覆盖会失灵（0.2.5 就修过这种脱节）：

- `.claude-plugin/plugin.json` 的 `version`
- `manifest.json` 的 `suite.version`
- 受影响 skill 的 `skills/<name>/SKILL.md` frontmatter `version:`
- `skills/branch-review-guard/CHANGELOG.md` 加一节（本仓库的变更史与决策记录都在这里，不在 README）
- **计数同步**（增删 skill / agent / 命令时）：`plugin.json` 的 `description`、`AGENTS.md`（套件内容节 + Claude Code 插件行）、`README.md`（亮点 + 仓库结构）、`marketplace.json` 的 description 里写死的 skill 数 / 子代理数 / 命令数（当前「4 skill + 11 只读子代理 + 5 命令」）要一并更新——0.3.0、0.5.0 都改过这些计数，脱节会让描述与实际不符。

### "自主执行"指令多处冗余，改一处要同步同侧其余几处

"被触发后一气呵成、中途不回问用户"的指令分两组冗余：

- **评审侧四处**：`skills/branch-review-guard/SKILL.md`（工作流程节）、`skills/branch-review-guard/prompts/orchestrate-branch-review.md`、`commands/review.md`、`commands/diff.md`。
- **设计侧三处**：`skills/design-panel/SKILL.md`、`skills/design-panel/prompts/orchestrate-design-panel.md`、`commands/design.md`。

0.2.9 修复的 bug 就是几处措辞不一致导致 agent 停在"建立上下文"等用户输入。设计侧的「一次澄清关卡」措辞同样要在这三处保持一致，且**不得承诺"不回复则按默认继续"**（纯 Markdown 无超时续跑通道，提问即结束本轮）。改任何一处的流程措辞，检查同侧其余几处。

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
