---
id: baseline/generated-and-vendored-low-priority
pack: baseline
type: calibration
dimension: design
severity: "-"
enabled: true
applies_to: {}
summary: 生成代码/锁文件/vendored 依赖/压缩产物 低优先级，抽样即可、不逐行严判
---

## 识别要点
- 生成代码（`*.g.dart`、protobuf/openapi 生成物、MapStruct 生成实现）、依赖锁文件（`package-lock.json`、`*.lock`、`dependency-reduced-pom.xml`）、vendored 第三方源码、压缩/构建产物。

## 校准动作
- 这类文件**不逐行严判**风格/复杂度；抽样确认无异常即可。
- 不因其体量计入覆盖率缺口，但在覆盖范围里注明"已识别为生成/vendored，抽样处理"。
- 真正的风险（如生成配置里引入了不该有的依赖）仍按对应维度判定。
