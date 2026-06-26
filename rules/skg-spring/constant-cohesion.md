---
id: skg-spring/constant-cohesion
pack: skg-spring
type: finding
dimension: design
severity: P2
enabled: true
applies_to:
  languages: [java]
summary: 功能专属常量内聚在功能模块、同一字符串收口到单一定义点，避免字符串漂移
---

## 识别要点
- 功能专属常量（Redis key、dataType 字符串、配置 key 等）是否被塞进公共大杂烩类（如公共 `RedisKeyConstants`），而非内聚在功能自己的模块/类里。
- 同一字符串（如 listener 的 dataType 与采集端登记）是否在多处各写一份字面量，而非引用单一常量。

## 取证方式
- 给出常量定义处与各引用处 `file:line`，指出存在多个独立定义 / 裸字面量重复。
- 说明影响：字符串漂移——一处改了另一处没改 → 静默不匹配（MQ dataType 对不上、Redis key 失效等）。

## 修法
- 功能专属常量内聚到该功能自己的模块/类里，不进公共大杂烩类。
- 同一字符串收口到单一常量定义点，所有引用方统一引用它，消除漂移。
