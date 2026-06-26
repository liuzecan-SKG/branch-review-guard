---
id: skg-spring/threadlocal-context-propagation
pack: skg-spring
type: finding
dimension: correctness
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, satoken, rocketmq]
summary: 并行/MQ/异步线程里 ThreadLocal（userId/tz/lang、LoginHelper/StpUtil）取不到，提交任务前要显式捕获传递；阻塞调用用专用有界池
---

## 识别要点
- 在 `@Async`、线程池 `submit/execute`、并行流 `parallelStream`、`CompletableFuture`、MQ 消费线程里调用 `LoginHelper.getUserId()` / `StpUtil.getLoginIdAsLong()` / 读取时区/语言等 ThreadLocal。
- 子线程读取的上下文是否在**主线程**先捕获并作为参数/闭包传入。
- 阻塞型远程/DB 调用是否提交到公共 `ForkJoinPool.commonPool()` 或共享定时线程池。

## 取证方式
- 给出"提交任务的位置"与"子线程内读 ThreadLocal 的位置"两处 `file:line`，确认中间没有显式传递。
- 命中即说明后果：子线程取到 null/错误用户 → 越权或数据错乱、i18n/时区取错。
- 公共池跑阻塞调用命中时，指出池被占满会拖垮其它使用方（可静态判定，按缺陷报）。

## 修法
- 提交任务前在主线程捕获 `Long userId = ...` 等，以参数/局部变量传入子线程，子线程内不再依赖 ThreadLocal。
- 阻塞调用用**专用有界线程池**，不复用公共 ForkJoinPool / 定时调度池。
- 本问题以正确性（数据错乱/越权）为主、可观测/运维（线程池打满）为辅，按正确性定级。
