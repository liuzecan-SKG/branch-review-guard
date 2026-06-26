# skg-spring 规则包

针对 SKG Health Global 技术栈（Spring Boot 3 / Dubbo / MyBatis-Plus / MongoDB 自研事务 / Sa-Token / Redisson / RocketMQ）的机制级评审规则包。**默认关闭**，由 `rules/config.yaml` 控制启用；启用后，各维度 reviewer 在通用 checklist 之外叠加本包规则。

规则文件 schema、reviewer 如何消费、严重度校准见上级 `rules/README.md`。

## finding 规则（要查的问题）

| id | 维度 | 默认严重度 | 一句话 |
| --- | --- | --- | --- |
| `skg-spring/txn-multitransactional` | correctness | P0 | 自研 `@MultiTransactional` 语义坑：内层未标注解、`commit=false` 裸调、self-call、异步逃逸 → Mongo 多步写非原子或被静默回滚。 |
| `skg-spring/aop-self-invocation` | correctness | P1 | 同类 `this.method()` 让 `@MultiTransactional`/`@DistributedLockRedisson`/`@Async` 静默失效（含 listener 模板方法），改用 `SpringUtils.getBean(self)`。 |
| `skg-spring/distributed-lock-redisson-spel-key` | correctness | P1 | `@DistributedLockRedisson` 的 SpEL key 参数必须在方法签名里，否则全局一把锁；只跨 bean 生效；长任务调大 `lockTime`。 |
| `skg-spring/threadlocal-context-propagation` | correctness | P1 | 并行/MQ/异步线程取不到 `ThreadLocal`（userId/tz/lang、`LoginHelper`/`StpUtil`），提交任务前显式捕获传递；阻塞调用用专用有界池。 |
| `skg-spring/collectionutil-vs-hutool` | correctness | P2 | 项目 `CollectionUtil`(common-core) ≠ hutool `CollUtil`，方法集不同（无 `emptyIfNull`），判空显式 `isEmpty`。 |
| `skg-spring/autoconfig-imports-registration` | design | P0 | common-* 模块无 `@ComponentScan`，新增需 Spring 管理的类必须登记到该模块 `AutoConfiguration.imports`，漏登记启动失败。 |
| `skg-spring/constant-cohesion` | design | P2 | 功能专属常量内聚在功能模块、同一字符串收口到单一定义点，避免字符串漂移。 |
| `skg-spring/commonresult-wrapper` | api | P2 | 对外接口统一返回 `CommonResult<T>`；改返回结构注意老客户端兼容。 |
| `skg-spring/satoken-auth-userid` | security | P1 | C 端接口用 `StpUtil.getLoginIdAsLong()` 取登录态，不信任前端传入 userId（横向越权）；写接口校验数据归属。 |
| `skg-spring/data-collect-protocol` | api | P1 | `DataCollectDto<T>` 外层采集契约 + 内层 DTO 同时分析；`data` 空列表行为；`@Valid` 缺失致内层校验失效。 |
| `skg-spring/watch-4g-data-length` | api | P1 | `@Watch4gDataLength` 手表/4G/蓝牙上报 DTO 的字段顺序、长度、count 字段与端侧协议强耦合，改动需端侧兼容。 |

## calibration 规则（降噪/绕过）

| id | 维度 | 一句话 |
| --- | --- | --- |
| `skg-spring/calibration-ddl-nacos` | observability | DDL/索引/建表脚本/Nacos 配置按惯例不在代码仓库，**直接越过、不报告**（不计 P0/P1，也不进待人工确认）。 |
| `skg-spring/calibration-ops-endpoint-auth` | security | 运维/内部写接口（`/admin/**` 等）默认由网关/内网/IP 白名单/独立 admin 鉴权保护，缺 C 端用户级鉴权**直接越过、不报告**；C 端接口越权仍严判。 |
