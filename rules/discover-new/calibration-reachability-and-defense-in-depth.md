---
id: discover-new/calibration-reachability-and-defense-in-depth
pack: discover-new
type: calibration
dimension: correctness
severity: "-"
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, dubbo]
  paths: ["**/*.java"]
summary: 定 P0/P1 前必须核实两层——触发路径业务状态机可达性（结构性不可达则降级）与下游/全局防线（精确匹配硬闸、全局 timeout/retries 兜底等 jar 内置与 Nacos 配置层）；只看单点缺陷高估可利用性是本项目最高频误报模式
---

## 识别要点

- 发现的影响主张形如"可被利用/会误删/会无限等待/会重试放大"时，先做两问：①从真实入口到缺陷点的业务状态机路径可达吗（有没有结构性前置挡住）？②缺陷点下游还有没有防线（精确匹配闸门、全局配置兜底、值已捕获为副本）？
- 全局配置兜底专查三层：注解参数 → jar 内置 `common-*/resources`（如 common-dubbo.yml）→ Nacos。否定型配置结论（"没配 timeout/retries"）未穷尽三层不成立。

## 校准动作

- 路径结构性不可达或下游有硬闸兜底的：降一档保留并写明缓解链，不进 P0；两者皆有的降至 P2 备注。
- **豁免边界（不放松）**：①"当前不可达"依赖的前置若在同分支/近期可变（如灰度开关、前端契约），只降级不越过，标"缓解链脆弱点"；②对外/C 端越权类不适用本条（越权闸门缺失本身即缺陷，不因"下游还有别的检查"降级）；③下游防线必须给 file:line 实证，"应该有兜底"不算。
