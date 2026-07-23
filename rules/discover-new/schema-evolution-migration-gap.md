---
id: discover-new/schema-evolution-migration-gap
pack: discover-new
type: finding
dimension: correctness
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [mybatis, mybatis-plus]
  paths: ["**/*.java", "**/*.sql", "**/*Mapper.xml"]
summary: schema/值集演进缺配套三件套——新列无存量回填（NULL 命中 Boolean.TRUE.equals 等三值陷阱）、新哨兵值无存量迁移且外溢到未适配的既有读侧、语义判定（存在行=已填写）被存量数据反例击穿
---

## 识别要点

- 新增列/新增哨兵值/改主键类型时追问三件事：①存量行是什么值（NULL/零行），代码所有判定对该值走哪个分支？②有没有配套回填/迁移 SQL（含各 region 库）？③既有读侧（含 admin/报表/其它服务）遇到新值会怎么展示？
- 三值布尔陷阱专查：`Boolean.TRUE.equals(x)` 与 `Boolean.FALSE.equals(x)` 对 NULL 的走向是否符合防御意图（NULL 应落安全分支）。
- "存在行=已填写"式语义判定，用存量零行用户与新哨兵行各推演一遍。

## 取证方式

- 给出实体字段、判定点、DDL/迁移脚本三处 file:line；"无回填脚本"属否定结论——按 DDL 不入库惯例（calibration-ddl-nacos）先问脚本管理位置，拿不到事实源标"待人工确认"，不判"已缺失"。

## 修法

- 新列三选一兜底：回填 SQL / 列默认值 + 实体默认值 / 代码显式把 NULL 当安全态（防御方向用 `Boolean.FALSE.equals` 判危险动作）。
- 新哨兵值上线前列出全部读侧清单并逐一适配或过滤；迁移 SQL 与代码同分支评审（惯例不入库的，在上线单里登记）。
