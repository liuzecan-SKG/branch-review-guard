---
id: skg-spring/data-collect-protocol
pack: skg-spring
type: finding
dimension: api
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
summary: DataCollectDto<T> 须外层采集契约 + 内层 DTO 同时分析；明确 data 空列表行为；@Valid 缺失致内层校验失效
---

## 识别要点
- 采集接口入参 `DataCollectDto<T>`：是否同时分析**外层采集契约**（设备/时间/类型等必填字段）与**内层泛型 DTO** 的字段与校验。
- 外层 `data` 为空列表 / null 时的行为是否明确（跳过、报错还是静默成功）。
- 外层对内层集合是否加了 `@Valid`——缺失则内层 DTO 的 `@NotNull/@Length` 等**不会级联生效**。

## 取证方式
- 给出 `DataCollectDto` 使用处与内层 DTO `file:line`，列出外层必填字段与内层关键校验。
- `@Valid` 缺失命中时说明后果：内层非法数据绕过校验直接入库/上报。
- 字段增删或必填变化时评估端侧上报协议兼容性。

## 修法
- 外层集合字段加 `@Valid` 触发内层级联校验；外层必填字段补 `@NotNull/@NotEmpty`。
- 明确并测试 `data` 空列表的边界行为，不要静默当成功。
- 内外层契约变更同步通知端侧，必填字段变更按兼容性风险处理。
