---
description: 提测/上线前对整条功能分支（相对 master 累计变更）做多维度综合代码评审，产出可发布性报告
argument-hint: "[branch | diff | recent <N> | module <模块名>] [--base <分支>] [--dimensions bug,security,...]"
---

# /branch-review-guard:review

对当前功能分支做一次**提测/上线前整分支综合代码评审**。

参数：`$ARGUMENTS`（留空 = `branch` 全量模式，相对 master 累计变更，最常用）。

## 执行方式

1. 调用本插件的 **`branch-review-guard` skill**（`branch-review-guard:branch-review-guard`），严格按其 `SKILL.md` 工作流程执行：确定范围 → 建立上下文（读 `*_DESIGN.md` / `*_CONTRACT.md` / commit message）→ 自动化先行(L1) → 加载 `rules/` 规则包 → 估规模分批 → 分维度评审 → 复用 `api-change-guard` / `endpoint-perf-review` → 汇总去重 → 产出单份中文报告。
2. 把 `$ARGUMENTS` 解析为该 skill 的模式与选项（`branch` / `diff` / `recent <N>` / `module <名>`、`--base`、`--dimensions`）。
3. **优先用专用维度子代理并行评审**：本会话支持子代理时，对每个批次按维度并行派发本插件提供的子代理，互相上下文隔离、各自只回传结构化发现：
   - 正确性/Bug → `bru-correctness`
   - 设计/可维护性/质量 → `bru-design`
   - 安全 → `bru-security`
   - 测试 → `bru-tests`
   - 可观测/运维/i18n → `bru-observability`
   不支持子代理时，按 SKILL.md 顺序多轮执行，结果一致只是更慢。
4. 强制全覆盖、显式声明覆盖率；运行时维度只给"需运行时验证项"，不下"已验证通过"。

最终回复遵循 SKILL.md `## 回复约定`：先报告链接，再完整报告正文。
