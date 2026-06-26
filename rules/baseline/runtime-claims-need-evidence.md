---
id: baseline/runtime-claims-need-evidence
pack: baseline
type: calibration
dimension: performance
severity: "-"
enabled: true
applies_to: {}
summary: 运行时维度（性能/并发/迁移真实表现）只输出"需运行时验证项"，禁止下"已验证通过"
---

## 识别要点
- 涉及真实性能（QPS/RT/p99、执行计划、火焰图）、并发竞态、降级/熔断真实行为、数据迁移在存量数据下表现的结论。

## 校准动作
- 这些维度静态评审**只能提出假设/风险**，统一输出为「需运行时验证项」。
- **禁止**对它们下"已验证通过 / 没问题"的结论。
- 不计入阻塞清单的"已确认缺陷"，而是列为待验证（除非有静态可证的明确错误，如把阻塞调用提交到公共 ForkJoinPool）。
