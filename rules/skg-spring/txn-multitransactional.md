---
id: skg-spring/txn-multitransactional
pack: skg-spring
type: finding
dimension: correctness
severity: P0
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, mongodb]
summary: 自研 @MultiTransactional 语义坑——内层未标注解、commit=false 裸调、self-call、异步逃逸导致 Mongo 多步写非原子或被静默回滚
---

## 识别要点
- Mongo 多步写（delete+save、批量 remove+insert、跨集合写等）所在方法或其调用链上是否真有 `@MultiTransactional`；只看注解字面存在不够。
- 协调者写法 `getTransaction=false`：内层被调方法是否**至少有一个**标了 `getTransaction=true`，否则事务栈为空、delete/save 各自裸跑、非原子。
- `commit=false` 的方法是否被某个协调者（`getTransaction=false + commit=true`）包裹后调用；裸调即 depth==0。
- 写操作是否在异步/子线程（`@Async`、线程池、并行流）中执行——会逃出当前线程的事务栈。
- 同方法内除 Mongo 外还写了 Redis/MySQL/MQ——这些不在该 manager 事务保护内，回滚不会撤销。

## 取证方式
- 判断"到底有没有真事务"必须看**具体被调方法**上的注解，不能按类推断：基类 `MongoServiceImpl`（common-mongodb）的 save/saveBatch/removeById/updateBatch 都**不带**注解，只有子类 DAO 覆盖时才标。给出被调方法 `file:line` 及其注解事实。
- 命中"内层全无注解"时，指出 delete 与 save 两处 `file:line`，说明非原子后果（删成功、存失败 → 数据丢失，曾整组 8 个数据类型中招）。
- `commit=false` 裸调命中时，说明会触发 "Orphan transaction intercept" 强制回滚、**静默失效不报错**。

## 修法
- 推荐：直接做多步写的方法自己标 `@MultiTransactional`（默认 `getTransaction=true`），方法进入即开 MONGO 事务，内部 DAO 无论带不带注解都自动加入当前事务。
- 用协调者模式时，确保内层确有 `getTransaction=true + commit=false` 的方法真正开事务，外层 `getTransaction=false + commit=true` 统一提交。
- 不要裸调 `commit=false` 方法；跨 bean 经代理调用（见 aop-self-invocation）。
- 需与 Redis/MySQL 一致时，明确标注哪边是 best-effort 或引入补偿，不要假设 Mongo 回滚会撤销它们。
