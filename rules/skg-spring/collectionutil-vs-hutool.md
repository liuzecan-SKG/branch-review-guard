---
id: skg-spring/collectionutil-vs-hutool
pack: skg-spring
type: finding
dimension: correctness
severity: P2
enabled: true
applies_to:
  languages: [java]
summary: 项目 CollectionUtil（common-core）≠ hutool CollUtil，方法集不同（无 emptyIfNull），判空应显式 isEmpty
---

## 识别要点
- import 的是项目 `com.skg.health.global.common.core.utils.CollectionUtil` 还是 hutool `cn.hutool.core.collection.CollUtil`；两者方法集不一致。
- 是否凭 hutool 记忆调用了项目类里**不存在**的方法（典型：`emptyIfNull`）。

## 取证方式
- 给出 import 行与调用处 `file:line`，确认所调方法在所用类里真实存在。
- 若 import 的是项目 `CollectionUtil` 却调用 `emptyIfNull` 等 hutool 专有方法 → 报（编译不过或语义不符）。

## 修法
- 判空统一用显式 `isEmpty` / `isNotEmpty`，不要依赖 `emptyIfNull` 这类 hutool 习惯写法。
- import 时看清是哪个类；确需 hutool 能力则显式 import hutool 并确认项目允许。
