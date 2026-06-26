---
id: skg-spring/watch-4g-data-length
pack: skg-spring
type: finding
dimension: api
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
summary: @Watch4gDataLength 手表/4G/蓝牙上报 DTO 的字段顺序、长度、count 字段与端侧协议强耦合，改动需端侧兼容
---

## 识别要点
- 带 `@Watch4gDataLength` 的手表/4G/蓝牙上报 DTO：字段**顺序**、各字段**长度**、`count` 计数字段是否与端侧协议一致。
- 是否在中间插入/删除/重排字段或改了长度定义——按固定长度/顺序解析的协议会整体错位。

## 取证方式
- 给出 DTO 字段定义 `file:line` 与注解参数，核对 count 字段与实际数据项数的对应关系。
- 任何顺序/长度/count 改动都标"端侧协议兼容性风险"，需端固件/小程序同步，给出待人工确认项。

## 修法
- 上报 DTO 字段顺序/长度视为对外协议，变更优先**追加在末尾**，不重排既有字段。
- 协议字段注释其顺序/长度约束（为什么这么排），便于后续维护。
- 破坏性协议变更必须与端侧约定版本并灰度。
