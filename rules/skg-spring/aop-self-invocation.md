---
id: skg-spring/aop-self-invocation
pack: skg-spring
type: finding
dimension: correctness
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, mongodb, redisson, rocketmq]
summary: 同类 this.method() 调用让 @MultiTransactional/@DistributedLockRedisson/@Async 静默失效（含 listener 模板方法 self-invocation）
---

## 识别要点
- 标了 `@MultiTransactional` / `@DistributedLockRedisson` / `@Async` / `@Transactional` 的方法是否被**同一个类内**的其它方法用 `this.method()`（或裸方法名）直接调用。
- listener / 模板方法：父类 `onMessage` → 子类抽象 `handle` 属于 self-invocation；注解若标在 `handle` 上则不经代理、不生效。
- `new X().annotated()` 直接 new 出对象再调注解方法，也不走代理。

## 取证方式
- 给出调用点 `file:line` 与被调注解方法 `file:line`，确认两者在同一 bean、且调用未经代理。
- 真伪判别：经接口注入、`SpringUtils.getBean(...)`、或从其它 bean 调入的不算 self-invocation，不报。
- 命中即说明后果：事务/锁/异步在该路径上形同虚设（静默，不抛错）。

## 修法
- 跨 bean 调用：`SpringUtils.getBean(自身接口或类).method()` 走代理，或把被注解方法下沉到独立 service。
- listener 只做纯转调，把注解下沉到被**跨 bean** 调用的 service 方法上。
- 这是设计味道（依赖代理的 self-call）也是正确性缺陷，按正确性定级、设计维度交叉引用。
