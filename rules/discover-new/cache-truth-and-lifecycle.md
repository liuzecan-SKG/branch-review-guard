---
id: discover-new/cache-truth-and-lifecycle
pack: discover-new
type: finding
dimension: correctness
severity: P1
enabled: false
applies_to:
  languages: [java]
  frameworks: [spring, redis]
  paths: ["**/*.java"]
summary: 缓存一致性/生命周期缺陷四形态——缓存当唯一真相源无回源兜底、负缓存/占位无 TTL 永久固化、失效依赖单条 MQ 无重试（撤权方向泄露窗口无界）、缓存 VO 加字段致存量整体误判失效惊群
---

## 识别要点

- 对新增/改动的缓存读写路径追问四件事：①缓存丢了从哪重建（有没有 DB 真相源）？②空值/占位有没有 TTL？③失效通知丢一条会怎样（尤其"撤销权限"方向）？④缓存对象加字段后，存量旧值反序列化会不会被判失效/触发集体回源？
- 高危形态：miss 重建后返回重建前引用；负缓存无 TTL；权限/共享快照仅靠 MQ 失效且监听 catch 后不重试不抛。

## 取证方式

- 给出写入点、读取点、失效点三处 file:line；"无 TTL"“无重试"这类否定结论用 Read 逐处核对（DLP 环境禁 grep 取证否定型结论）。
- 撤权方向泄露要说明窗口边界（有 TTL=有界，仅 MQ=无界）。

## 修法

- 缓存永远可重建：保留 DB 真相源与回源路径；负缓存/占位必须带 TTL。
- 权限类快照双保险：MQ 失效 + 兜底 TTL；监听失败要重试或抛出进重试队列。
- 缓存 VO 演进用版本号/字段可空兼容，避免"加字段=全量失效"。
