---
id: discover-new/loop-remote-call-nplus1
pack: discover-new
type: finding
dimension: performance
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, dubbo]
  paths: ["**/*.java"]
summary: 循环/forEach 内单条 Dubbo/远程调用构成真 N+1，应提供批量接口或把调用提到循环外取一次；含"被调方在热点/共享路径上背无缓存字典查询"这一放大面
---

## 识别要点
本规则覆盖 N+1 的**两个视角**，互为放大：

**A. 调用方视角（循环内远程调用）**
- 在 `for` / `stream().forEach` / `list.forEach` 循环体内出现：`@DubboReference` 服务调用、`remoteXxxService.xxx(oneId)`、单条 Mapper 查询、循环内取文件前缀等远程/跨服务调用。
- 典型：按列表循环逐个拉信息、循环内逐条状态查询、循环内逐条取某前缀。
- 也包括"全量列表 + 内存 filter"替代按条件单查。

**B. 被调方视角（热点/共享方法内的无缓存字典查询）**
- **被多方共享的通用方法**（如 `info` / `detail` / `getXxxVo`，被多个 `@DubboReference` 消费者或多个上层调用）里，主路径上**无条件**执行一次"翻译/补全字典字段"的查询：把 code 翻成 name、按 code 查地区/单位/配置枚举等。
- 该查询命中的是**近静态引用/字典数据**（国家、地区、单位、机型、配置枚举、区号等，变更频率极低），却走**无缓存**的 DB/远程查询（`selectOne`、按 code `list().get(0)`、`orderByDesc(...).last("limit 1")`）。
- 该字段对**大多数调用方并非必需**（列表页只要昵称/头像却顺带解析了 countryName）——"胖方法被窄需求复用"。
- 放大关系：当 B 类方法又被 A 类循环调用时，字典查询次数 ≈ 上层调用次数 × N（本栈曾观测单一字典查询被放大到 11 万次/日级）。

## 取证方式
- A：确认调用在循环体内、每次迭代执行一次、依赖迭代变量；确认无批量版本被使用（契约是否已提供 `listByIds/batchInfo/mapByIds`）；估算 N（列表长度上限）。
- B：给出"翻译字典字段"的调用点 `file:line` 与其落地查询 `file:line`，确认**无 `@Cacheable`/Redis/进程内缓存**兜底；确认被查数据的静态性；评估该方法消费者数量与是否在 N+1 路径上。
- 区分：字段确为方法**核心返回**且调用低频 → 不算 B（命中要件是"静态数据 + 无缓存 + 热点/共享/被放大"）。

## 修法
- A：提供并改用批量接口 `Map<Long,XxxVo> batchInfo(Collection<Long> ids)`，循环外一次拉齐再进程内组装；循环内不变的远程结果提到循环外取一次；"全量+内存 filter"改为按业务条件单查。
- B：给字典查询加缓存（`@Cacheable`/Redis 或 Caffeine/静态 Map + 变更失效，空值负缓存防穿透）；通用方法保持精简，非必要字段解析改**可选/惰性**（加类似 `xxxFlag` 开关，只有要展示的调用方才解析）；需要批量时提供 `Map<String,String> namesByCodes(Collection<String>)`。
- 与开发侧一致：coding-standards 机制 G「静态引用/字典数据必须缓存复用，禁止把无缓存查库放进热点或多消费者共享的 RPC 主路径」是本规则 B 面的开发侧对照，评审命中即引 G 修法。
