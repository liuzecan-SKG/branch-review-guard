---
id: discover-new/calibration-dependency-attribution-by-review-mode
pack: discover-new
type: calibration
dimension: design
severity: "-"
enabled: true
applies_to:
  languages: [java]
  frameworks: [maven]
  paths: ["**/pom.xml"]
summary: pom/依赖类发现必须先按当前评审口径核归属（diff 模式看工作区 diff，branch 模式看三点 diff），master 既有的依赖不得报为"本次新增"
---

## 识别要点

- 发现类是"某 pom 新增了 X 依赖（死依赖/多余依赖/版本问题）"，但**未核实该依赖是本次改动引入还是 master 既有**。
- 常见误报根因：混用评审口径——
  - `diff` 模式评审范围 = 工作区 diff（`git diff` 未暂存 + `git diff --cached` 已暂存）；
  - `branch` 模式评审范围 = 三点 diff（`git diff master...HEAD`，自 merge-base 起本分支引入的改动）。
  - 用错口径会把 master 既有依赖当成"本次新增"。

## 校准动作

- 报 pom/依赖类发现前，**先按当前评审口径亲眼核归属**：
  - `diff` 模式：`git diff -- <该pom>` 看工作区到底改了什么；
  - `branch` 模式：`git diff master...HEAD -- <该pom>` 看相对 master 的净变化。
- 该依赖在当前口径下的 diff 为空 = 本次未改、master 既有 → **移出本次发现范围**，不报"本次新增死依赖"。
- 确在当前口径 diff 内新增、且无消费者（如加了 junit 但模块无 `@Test`）→ 才按死依赖报。
- 样例形态：同一 pom 的同一依赖，一次评审按三点 diff 判"相对 master 为空、移出范围"，另一次按工作区 diff 判"新增死依赖该删"——根因即口径差。以当前评审模式的口径为准。
