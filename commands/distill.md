---
description: 从目标项目本地最近 N 份评审报告聚类重复发现，生成候选规则草稿（漏报→finding、误报→calibration），附 triage 一页清单；人工确认后先落项目本地 branch-review-rules/ 试用，服役出战绩再晋升插件仓库
argument-hint: "[N（默认 5）] [--pack <草稿 pack，默认 local（首落位）>]"
---

# /branch-review-guard:distill

把评审报告里**反复出现的发现**沉淀为可插拔规则草稿，形成"评审 → 规则 → 更准的评审/开发"的反馈闭环。

参数：`$ARGUMENTS`（`N` = 取最近几份报告，默认 5；`--pack` = 草稿 frontmatter 的 pack，默认 `local`——草稿的宿命是先进项目本地 `branch-review-rules/` 试用（两段式落位首段），不混进上游预置的 `skg-spring`）。

> **自主一气呵成**：被调用后连贯跑完并直接产出草稿与清单，不要中途停下来问用户。仅在本地找不到任何评审报告时中止说明。
> **只出草稿，不落位**：本命令绝不直接写入 `branch-review-rules/` 或插件 `rules/`——落位永远过人工关卡（人裁决"值不值得进试用区"后由 agent 代劳移入并记 LEDGER）。

## 执行方式

1. 调用本插件 `branch-review-guard` skill 的 `prompts/distill-rules.md`，严格按其流程执行：
   - 在**目标项目本地**定位报告目录（优先 `tools/branch-review-guard/reports/`，否则项目根 `branch-review-reports/`）；
   - 读取最近 N 份**评审报告**（按文件名时间戳倒序，**只取 `branch-review-guard-*` 前缀**——排除设计阶段的 `design-panel-*` 报告与精炼设计稿 `*_DESIGN.md`，它们不是 distill 输入源：设计裁决不沉淀为规则，design 与 review 共享 rules 供给是单向的）；
   - **先归"代码实例"（同 file + 同根因，不死磕 file:line）再计数**：同一实例跨报告重复只计 1 次；
   - 聚类重复发现（同维度 + 同根因模式跨 **≥2 个不同实例** → 候选 `finding`；附录"对抗验证记录"被杀/降级同类跨 ≥2 实例 → 候选 `calibration`）；
   - **遗留项分诊**：同一实例在 ≥2 份报告中反复报出、位置基本未变的，**不算漏报**（评审每次都报了、是没改），从 finding 剔除、单列，给两个出口——排期修 known-issue（不生成规则）/ 判定不重要则转 `calibration` 豁免；
   - **四处对照去重**：插件已启用包 + 项目根 `branch-review-rules/` + `rule-drafts/` 未审草稿（命中则**合并证据进原草稿、不新开文件**）+ 已归档草稿；
   - 按 `rules/README.md` schema 生成草稿到报告目录旁的 `rule-drafts/`（frontmatter `enabled: false`、默认 `pack: local`）；
   - **战绩回写**：统计报告中「触发规则/规则误报/规则降噪」标记，回写报告侧 `FEEDBACK.md`（命中÷存活）；跑完更新 `rule-drafts/.distill-state` 水位线。
2. 最终回复 = **triage 一页清单**：每条 `summary｜类型维度｜证据实例数｜建议裁决（adopt 附误杀模拟 file:line 反例，无反例的 adopt 无效）｜风险` + **遗留项清单（含建议出口）** + 可晋升候选/建议退役 + 下一步指引（两段式：人一行裁决 → agent 代劳移入 `branch-review-rules/` 并记 LEDGER；服役命中 ≥3 且存活率 ≥2/3 再晋升插件仓库；遗留项判定不重要的可用 `/branch-review-guard:rule` 一键转 calibration 草稿）。
