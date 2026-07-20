---
id: discover-new/txn-external-side-effects-after-commit
pack: discover-new
type: finding
dimension: correctness
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
  paths: ["**/*.java"]
summary: Spring @Transactional 方法内发 MQ / 跨服务 Dubbo RPC / 删 Redis，DB 回滚后这些外部副作用不可撤销，留下孤儿写或脏缓存
---

## 识别要点
- 方法或其外层标注 Spring `@Transactional`（关系库事务），方法体内出现：
  - `rocketMQTemplate.asyncSend` / `send` / `convertAndSend` 等 MQ 发送；
  - `@DubboReference` / `remoteXxxService.xxx()` 跨服务 RPC；
  - `redisTemplate` / `RedisUtils.delete` / `setCacheObject` / `cacheXxxList` 等 Redis 写删。
- 典型组合：先 DB 写、后发 MQ/刷缓存；或事务方法内调远程解绑/建友；或在事务内 `cacheUserFriendList`。
- 与自研 `@MultiTransactional`（Mongo 多步写）不同：本规则针对 **Spring 关系库事务** 含 **非事务外部副作用**。

## 取证方式
- 找到 `@Transactional` 边界（注解可能在当前方法，也可能在类或外层 coordinator 方法——向上追溯调用栈）。
- 确认外部副作用在事务 commit **之前**发生：DB 回滚时 MQ 已发 / RPC 已调用 / 缓存已删或已写。
- 判真伪：若 RPC/MQ/Redis 操作被包在 `TransactionSynchronizationManager.registerSynchronization(afterCommit())` 或事务提交后的独立步骤中，则不命中。
- 影响放大条件：RPC 失败被 catch 吞、重试命中终态（如 CLAIMED）return null、缓存无 TTL。

## 修法
- 把 MQ 发送、跨服务 RPC、Redis 刷新挪到 **事务提交后**：用 `TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){ afterCommit(){...} })`，或拆出独立非事务步骤在事务方法返回后执行。
- 缓存刷新统一走 afterCommit，避免 `@Transactional` 方法内直接 `cacheXxx`。
- 若 RPC/MQ 必须与 DB 同生共死，改用 Saga / 本地消息表 / outbox 保证最终一致，不要依赖 Spring 事务回滚覆盖远程副作用。
- 重试路径对"终态但缺副作用"要可补偿（如置 CLAIMED 后建友失败，重试应重组入参走幂等 bind）。
