---
id: skg-spring/calibration-ddl-nacos
pack: skg-spring
type: calibration
dimension: observability
severity: "-"
enabled: true
applies_to:
  languages: [java]
  frameworks: [mybatis, mongodb]
summary: DDL/索引/建表脚本/Nacos 配置按惯例不在代码仓库，直接越过、不报告
---

## 识别要点
- 以"配置/脚本缺失"为由的发现：DDL/索引/建表脚本未在分支 diff、Nacos 配置不在仓库、`*.sql` 不在分支等。

## 校准动作
- 团队惯例：DDL 由 DBA 在库执行、Nacos 配置在控制台维护，**不入代码仓库**。此类**直接越过、不报告**。
- 不计入 P0/P1 阻塞清单，**也不列入待人工确认 / 上线协同项**；`*.sql` 不在分支不是减分项。
- 边界：若分支内**确实包含** `*.sql`，则照常评估可回滚性 / 存量数据兼容 / 大表锁表（那是真 diff，不在本校准豁免内）。
- 不放松：代码自身的幂等/空指针等缺陷仍按对应维度判定，不得借"配置缺失"名义重提。
