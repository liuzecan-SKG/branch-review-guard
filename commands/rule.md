---
description: 从一条具体发现或一句自由描述，快捷生成一条候选规则草稿（finding=以后主动查 / calibration=以后豁免降噪），走与 distill 相同的两段式落位——人工确认后先落项目本地 branch-review-rules/ 试用，服役出战绩再晋升插件仓库
argument-hint: "<问题/模式描述> [--type finding|calibration] [--pack <草稿 pack，默认 local（首落位）>] [--dimension <维度>] [--severity <P0|P1|P2|Nit>]"
---

# /branch-review-guard:rule

把**一条你已经确信值得规则化的经验**一键沉淀为可插拔规则草稿——不必等 `/branch-review-guard:distill` 攒够 ≥2 次。典型用途：① 把 distill 列出的"遗留项/误报项"一句话转成规则；② 看一次就确信要规则化的强 case。

参数：`$ARGUMENTS`
- 第一段自由文本 = 要规则化的**问题或模式描述**（必填）。
- `--type` = `finding`（以后主动查这类问题）或 `calibration`（以后豁免/降噪这类）。缺省则由描述语气推断，拿不准时默认 `finding` 并在输出里说明。
- `--pack` = 草稿 frontmatter 的 pack，默认 `local`（首落位是项目本地 `branch-review-rules/` 试用区；晋升团队家时才改 `discover-new`，不混进上游预置的 `skg-spring`）。
- `--dimension` = `correctness|design|security|tests|observability|api|performance`，缺省按描述归类。
- `--severity` = 建议默认严重度（finding 用；calibration 用 `-`）。

> **自主一气呵成**：被调用后连贯跑完并直接产出草稿与说明，不中途回问用户（描述本身歧义到无法归类时才回问一次）。
> **只出草稿，不落位**：与 distill 完全相同的关卡——绝不直接写入 `branch-review-rules/` 或插件 `rules/`；落位过人工关（确认后移入项目本地即生效，服役出战绩再晋升插件仓库）。

## 与 distill 的分工（重要）

- `distill` = **数据驱动**：靠"跨 ≥2 个代码实例反复出现"这个阈值防过拟合，机器聚类。
- `rule` = **人担保**：本命令**绕过了那个 ≥2 次阈值**，泛化判断由**你**负责。正因如此，关卡一道不能松：草稿 `enabled: false` + 人工 review 后移入 `branch-review-rules/` 才生效（首落位只影响本项目、移出即撤销）。若你只有"一次的 case"又拿不准是否该规则化，用 distill 的"观察中"清单，别急着用本命令固化。

## 执行方式

> 权威流程见本插件 `branch-review-guard` skill 的 `prompts/add-rule.md`，严格按其执行。下为摘要：

1. **解析意图**：从描述提炼——这是"要查的漏报模式"(finding) 还是"要豁免的误报/不重要项"(calibration)；归到哪个 `dimension`；建议 `severity`；`applies_to`（语言/框架/路径）尽量从描述推断，推断不出留空并注明。
2. **对照现有规则去重**：读插件当前 `rules/` 已启用包（各规则 `summary`/识别要点）。已有规则覆盖 → 不新建，改输出"建议修订现有规则 `<id>`"；未覆盖 → 建草稿。
3. **定位落地目录**：草稿写到 `<报告目录>/rule-drafts/`（`<报告目录>` = 优先 `tools/branch-review-guard/reports/`，否则项目根 `branch-review-reports/`；目录不存在即创建）。**与 distill 同一处**，便于统一 review。
4. **生成草稿**（严格按 `rules/README.md` schema）：
   - frontmatter：`id: <pack>/<短名>`、`pack`、`type`、`dimension`、`severity`（calibration 用 `-`）、`enabled: false`、`applies_to`、`summary`。
   - 正文：finding 写"识别要点 / 取证方式 / 修法"；calibration 写"识别要点 / 校准动作"，且**必须写清豁免边界**（哪些情形不豁免——参考 `rules/skg-spring/calibration-ddl-nacos.md`）。
   - "识别要点"必须描述**模式**（注解/调用形态/代码结构），**不得绑定具体业务类名或某个 file:line**（防过拟合，与 distill 同一纪律）。
   - 文件顶部注释块：来源 = "手动 `/branch-review-guard:rule`，录入人判断"+ 原始描述（作为证据链，正式入库时删除）。
5. **最终回复**：草稿文件路径 + 一句话说明（type/dimension/severity/pack、为何这样归类）+ 下一步指引（两段式：人工确认 → 移入项目根 `branch-review-rules/` 即生效 + 记 LEDGER；本地服役命中 ≥3 且存活率 ≥2/3 → 晋升插件仓库 `rules/discover-new/`，改 pack/id → commit → 置 enabled → 发版后全团队生效）。
