---
id: skg-spring/distributed-lock-redisson-spel-key
pack: skg-spring
type: finding
dimension: correctness
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, redisson]
summary: @DistributedLockRedisson 的 SpEL key 参数必须在方法签名里，否则解析为 null = 全局一把锁；只跨 bean 生效；长任务需调大 lockTime
---

## 识别要点
- `@DistributedLockRedisson(key = "#xxx")` 里 SpEL 引用的参数（`#userId` 等）是否真出现在该方法签名中；不在签名 → 解析为 null。
- 该带锁方法是否被跨 bean 调用（self-call 失效，见 aop-self-invocation）。
- 长任务（重算、批处理、循环写）是否仍用默认 `lockTime=30` 秒。

## 取证方式
- 给出注解 `file:line` 与方法签名参数列表，指出 SpEL 表达式引用的名字是否缺失。
- 命中"参数缺失"时说明后果：所有用户共用一把锁（相互串行阻塞），且与按 userId 加锁的其它路径**不互斥**（仍会并发冲突）。
- 长任务命中时，估算执行时长是否可能超过 `lockTime`，锁中途过期 → 临界区失去保护。

## 修法
- 把 SpEL 引用的参数提进方法签名；范式：外层（无锁、签名不变）先查出 userId → `SpringUtils.getBean(self).innerWithLock(userId, ...)`，锁内重查校验。
- 长任务显式调大 `lockTime`（按最坏耗时留余量）。
- 注意锁切面 `@Order(HIGHEST_PRECEDENCE + 1)` 先于事务执行（先拿锁再开事务），勿依赖反向顺序。
