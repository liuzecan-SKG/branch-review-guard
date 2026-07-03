---
description: 从目标项目本地最近 N 份评审报告聚类重复发现，生成 rules/ 候选规则草稿（漏报→finding、误报→calibration），人工确认后再落插件仓库
argument-hint: "[N（默认 5）] [--pack <目标包，默认 skg-spring>]"
---

# /branch-review-guard:distill

把评审报告里**反复出现的发现**沉淀为可插拔规则草稿，形成"评审 → 规则 → 更准的评审/开发"的反馈闭环。

参数：`$ARGUMENTS`（`N` = 取最近几份报告，默认 5；`--pack` = 草稿建议归属的规则包，默认 `skg-spring`）。

> **自主一气呵成**：被调用后连贯跑完并直接产出草稿与清单，不要中途停下来问用户。仅在本地找不到任何评审报告时中止说明。
> **只出草稿，不改规则包**：本命令绝不直接写入 `rules/`（插件是独立仓库，规则变更需人工确认后提交到插件仓库）。

## 执行方式

1. 调用本插件 `branch-review-guard` skill 的 `prompts/distill-rules.md`，严格按其流程执行：
   - 在**目标项目本地**定位报告目录（优先 `tools/branch-review-guard/reports/`，否则项目根 `branch-review-reports/`）；
   - 读取最近 N 份报告（按文件名时间戳倒序）；
   - 聚类重复发现（同维度 + 同根因模式 ≥2 次 → 候选 `finding`；附录"对抗验证记录"中被杀/降级的同类 ≥2 次 → 候选 `calibration`）；
   - 对照当前已启用 `rules/` 包去重，已有规则覆盖的不再生成；
   - 按 `rules/README.md` schema 生成草稿到报告目录旁的 `rule-drafts/`（frontmatter `enabled: false`）。
2. 最终回复：草稿清单 + 每条的证据出处（哪几份报告的哪几条发现）+ 建议 pack 归属 + 下一步指引（人工确认后 commit 到插件仓库 `rules/<pack>/` 并置 `enabled: true`）。
