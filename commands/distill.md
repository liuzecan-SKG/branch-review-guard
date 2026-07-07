---
description: 从目标项目本地最近 N 份评审报告聚类重复发现，生成 rules/ 候选规则草稿（漏报→finding、误报→calibration），人工确认后再落插件仓库
argument-hint: "[N（默认 5）] [--pack <目标包，默认 discover-new>]"
---

# /branch-review-guard:distill

把评审报告里**反复出现的发现**沉淀为可插拔规则草稿，形成"评审 → 规则 → 更准的评审/开发"的反馈闭环。

参数：`$ARGUMENTS`（`N` = 取最近几份报告，默认 5；`--pack` = 草稿建议归属的规则包，默认 `discover-new`——团队沉淀区，不混进上游预置的 `skg-spring`）。

> **自主一气呵成**：被调用后连贯跑完并直接产出草稿与清单，不要中途停下来问用户。仅在本地找不到任何评审报告时中止说明。
> **只出草稿，不改规则包**：本命令绝不直接写入 `rules/`（插件是独立仓库，规则变更需人工确认后提交到插件仓库）。

## 执行方式

1. 调用本插件 `branch-review-guard` skill 的 `prompts/distill-rules.md`，严格按其流程执行：
   - 在**目标项目本地**定位报告目录（优先 `tools/branch-review-guard/reports/`，否则项目根 `branch-review-reports/`）；
   - 读取最近 N 份**评审报告**（按文件名时间戳倒序，**只取 `branch-review-guard-*` 前缀**——排除设计阶段的 `design-panel-*` 报告与精炼设计稿 `*_DESIGN.md`，它们不是 distill 输入源：设计裁决不沉淀为规则，design 与 review 共享 rules 供给是单向的）；
   - **先归"代码实例"（同 file + 同根因，不死磕 file:line）再计数**：同一实例跨报告重复只计 1 次；
   - 聚类重复发现（同维度 + 同根因模式跨 **≥2 个不同实例** → 候选 `finding`；附录"对抗验证记录"被杀/降级同类跨 ≥2 实例 → 候选 `calibration`）；
   - **遗留项分诊**：同一实例在 ≥2 份报告中反复报出、位置基本未变的，**不算漏报**（评审每次都报了、是没改），从 finding 剔除、单列，给两个出口——排期修 known-issue（不生成规则）/ 判定不重要则转 `calibration` 豁免；
   - 对照当前已启用 `rules/` 包去重，已有规则覆盖的不再生成；
   - 按 `rules/README.md` schema 生成草稿到报告目录旁的 `rule-drafts/`（frontmatter `enabled: false`）。
2. 最终回复：草稿清单 + **遗留项清单（含建议出口）** + 每条的证据出处（哪几份报告的哪几条发现）+ 建议 pack 归属 + 下一步指引（人工确认后 commit 到插件仓库 `rules/<pack>/` 并置 `enabled: true`；遗留项判定不重要的可用 `/branch-review-guard:rule` 一键转 calibration 草稿）。
