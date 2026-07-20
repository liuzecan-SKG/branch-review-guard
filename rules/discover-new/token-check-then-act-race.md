---
id: discover-new/token-check-then-act-race
pack: discover-new
type: finding
dimension: correctness
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, redis]
  paths: ["**/*.java"]
summary: 一次性令牌/资源转正走 check-then-act（先读 token/先 count 判定，业务完成才删 token/才落库），无锁无唯一索引兜底 → 并发或重试可重复落库/夺绑
---

## 识别要点
- 一次性令牌消费：`getCacheObject(token)` 读出 token → 执行业务（落库/认领）→ 业务成功后 `deleteObject(token)`。删除在后。
- 资源转正/建友：`if (count(userId) > 0) reject; else saveBatch(...)` 之类 check-then-act，无分布式锁、无唯一索引。
- 状态竞态：过期清理任务与"认领转正"两条路径都能改同一资源，无交叉校验影响行数/版本号。
- MQ 消费创建：`onMessage` 中 check-then-act 建关系，无幂等键/无唯一约束兜底。

## 取证方式
- 确认 token 删除/资源写入顺序：是否"业务在前、撤销在后"。改成原子消费是否可行（`DELETE token` 返回值判定，或 Lua）。
- 确认是否存在唯一索引兜底（`uk_username` / `uk(userId, friendId)` 等）：有则影响降级（重复落库被 DuplicateKey 挡），但夺绑/竞态类仍需处理。
- 确认并发面：用户可主动重试 / MQ 至少一次重投 / 过期任务并行。
- 确认无 `@DistributedLockRedisson` 且 SpEL key 正确归一化（关联 skg-spring/distributed-lock-redisson-spel-key）。

## 修法
- 一次性令牌：改为"先原子消费"——`redis.delete(token)` 返回 true 才继续，或 Lua 原子 getDel；或加分布式锁。
- 资源转正/建友：加分布式锁 + DB 唯一索引兜底；`agree`/`bind` 对双方都校验上限。
- 过期 vs 认领竞态：清理方法返回"是否真删"（影响行数），调用方据返回值决定后续；认领前再校验资源仍处可认领态。
- MQ 消费：消费幂等键 + 唯一约束 + DuplicateKey 走 update。
- 豁免边界：单线程内部、确无并发可能（需取证）的 check-then-act 可降级。
