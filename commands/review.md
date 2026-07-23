---
description: 提测/上线前对整条功能分支（相对 master 累计变更）做多维度综合代码评审，产出可发布性报告
argument-hint: "[branch | diff | recent <N> | module <模块名>] [--base <分支>] [--dimensions bug,security,...] [--thorough]"
---

# /branch-review-guard:review

对当前功能分支做一次**提测/上线前整分支综合代码评审**。

参数：`$ARGUMENTS`（留空 = `branch` 全量模式，相对 master 累计变更，最常用）。

> **自主一气呵成**：被调用后连贯跑完整条流程并**直接产出报告**，中途**不要停下来问用户**"是否继续 / 是否开始评审"。仅在 base 分支无法确定、命令参数歧义、或范围内无变更（diff 为空）时才中止回问。diff 很大（数百文件/上万行）也按"分批全覆盖"自动跑完，不因体量暂停。**同一 SHA / diff 与历史报告一致不是跳过或降级的理由**（换模型复审、多轮、交叉确认都是正当的"同代码重看"）——被调用一次就完整跑一次编排，不以"无信息增益/已评审过"偷懒（见 SKILL.md `## 每次评审都是独立执行`）。

## 执行方式

1. 调用本插件的 **`branch-review-guard` skill**（`branch-review-guard:branch-review-guard`），严格按其 `SKILL.md` 工作流程执行：确定范围 → 建立上下文（读 `*_DESIGN.md` / `*_CONTRACT.md` / commit message）→ 自动化先行(L1) → 加载 `rules/` 规则包 → 估规模分批 → 分维度评审 → 复用 `api-change-guard` / `endpoint-perf-review` → **对抗性验证（P0/P1）** → 汇总去重 → **完整性核查** → 产出单份中文报告。
2. 把 `$ARGUMENTS` 解析为该 skill 的模式与选项（`branch` / `diff` / `recent <N>` / `module <名>`、`--base`、`--dimensions`、`--thorough` 高风险批次 loop-until-dry 多轮扫描，**受规模门槛控制**：标准档/轻量档不开多轮、至多 1 轮定向聚焦，见 SKILL.md `## 范围边界` 规模分档）。
3. **优先用专用子代理并行**：本会话支持子代理时，按本插件提供的子代理派发，互相上下文隔离、各自只回传结构化结果：
   - 维度评审（按批并行）：正确性/Bug → `bru-correctness`、设计/可维护性/质量 → `bru-design`、安全 → `bru-security`、测试 → `bru-tests`、可观测/运维/i18n → `bru-observability`、业务语义/不变式 → `bru-business-invariant`
   - 对抗性验证（每条 P0/P1 × 3 视角并行 + 正例/零发现 × 假设证伪）→ `bru-skeptic`（视角：证据核实 / 规则校准 / 触发路径 反驳已报发现降误报；假设证伪 证伪"正例/做得好/零发现批次"捞漏报；聚合规则见 skill 的 `prompts/verify-findings.md`）
   - 完整性核查（报告定稿前 1 个）→ `bru-critic`
   不支持子代理时，按 SKILL.md 顺序多轮执行，结果一致只是更慢。
4. 强制全覆盖、显式声明覆盖率；阻塞清单只收经对抗验证的发现；运行时维度只给"需运行时验证项"，不下"已验证通过"。

最终回复遵循 SKILL.md `## 回复约定`：先报告链接，再完整报告正文，正文后固定附一段提示——

> 是否需要我将可以直接代码落地修复的项提炼成 todo 清单（剔除纯运行时验证、发版编排、人工确认类）？按「必要性 × 成本」分三档，每项说明：问题 → 不改的后果 → 为什么值得改。
