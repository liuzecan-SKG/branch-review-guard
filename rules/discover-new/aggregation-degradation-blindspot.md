---
id: discover-new/aggregation-degradation-blindspot
pack: discover-new
type: finding
dimension: observability
severity: P2
enabled: false
applies_to:
  languages: [java]
  frameworks: [spring, dubbo]
  paths: ["**/*.java"]
summary: 聚合/降级路径三查——粒度（整批 catch 连坐 vs per-item）、对称性（装饰字段有降级而核心链裸奔，或反之）、可观测（降级/兜底/灰度分流无指标无日志，设计性空与故障性空不可区分）
---

## 识别要点

- 对聚合接口（一次组装多来源字段/多条目）追问三件事：①catch 粒度是 per-item 还是整段（单条脏数据会不会连坐整批）？②核心链与装饰字段的降级策略是否对称（核心裸奔 = 单点拖垮整页）？③每条降级/兜底分支有没有指标或结构化日志（降级率可见吗）？
- 灰度分流/新旧路径切换点零观测 = 放量决策无数据，单列提示。
- "正常返回空"与"故障兜底空"走同一条静默路径的，标"不可区分"缺陷。

## 取证方式

- 给出 catch 块范围、降级分支、埋点缺失处的 file:line；降级率类是运行时表现，只写"需运行时验证/需补埋点"，不写"已导致故障"。

## 修法

- 批处理 catch 收敛到 per-item；核心链给显式降级或快速失败策略（与装饰字段策略对称设计）。
- 每条降级分支至少一个 counter 或带原因字段的结构化日志；灰度分流打 mode 标识。
