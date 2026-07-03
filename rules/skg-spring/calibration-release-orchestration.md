---
id: skg-spring/calibration-release-orchestration
pack: skg-spring
type: calibration
dimension: observability
severity: "-"
enabled: true
applies_to:
  languages: [java]
summary: 上线协同/发版编排类提示（新表/MQ topic/消费组/缓存 key 预建、配置各环境就绪、发版顺序）由团队独立上线 checklist 兜底，直接越过、不报告
---

## 识别要点

- 以"需提前建好 / 需上线协同 / 需配置就绪 / 需按顺序发版"为由的发现或备忘，典型如：
  - 依赖新表 / 新 MQ topic / 新消费组 / 新缓存 key / 新中间件，"需提前创建"；
  - Nacos/配置中心配置项"需各环境配置就绪"；
  - 发版顺序、灰度编排、上下游协同发布类提醒。

## 校准动作

- 团队发版流程有**独立的上线 checklist** 兜底此类事项。命中后**直接越过、不报告**：
  - 不计入 P0/P1 阻塞清单；
  - 不进"待人工确认"；
  - **也不在报告中留任何备忘/协同清单小节**（与 [calibration-ddl-nacos](calibration-ddl-nacos.md) 同口径）。
- 边界（不在本豁免内，照常评审）：
  - 分支内**确实包含**的 `*.sql` / 配置文件 diff——那是真 diff，照常评估可回滚性 / 存量数据兼容 / 大表锁表；
  - **代码自身缺陷**：框架装配/组件注册缺失导致启动失败（见 autoconfig-imports 类规则）、代码里硬编码环境配置、开关缺省值错误等，仍按对应维度/规则判定，不得借"上线协同"名义豁免。
