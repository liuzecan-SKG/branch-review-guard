---
id: discover-new/calibration-baseline-attribution
pack: discover-new
type: calibration
dimension: correctness
severity: "-"
enabled: true
applies_to:
  languages: [java]
  paths: ["**/*"]
summary: 报缺陷前先 git blame/log 做基线归责——master 存量缺陷、与既有产品口径一致的行为不算本分支回归，不进本次阻塞清单；但存量高危（越权/数据损坏）仍须显式转交，不得静默豁免
---

## 识别要点

- 每条 P0/P1 定稿前问一句：这段代码是本分支引入/改动的吗？`git log -L`/blame 到引入 commit；行为类问题对照 master 同路径行为与既有设计文档。
- diff/branch 模式的门禁只对"本次引入或恶化"的缺陷负责。

## 校准动作

- 归责为存量的：从阻塞清单移出，标「存量 · 转交」单列（含引入 commit），不计本次可发布性结论。
- 与既有产品决策一致的行为对齐：不判回归，至多提示"口径知会"。
- **豁免边界（不放松）**：①存量但"上线即活"的高危（越权、跨用户数据损坏、账号接管）必须显式转交并建议独立排期，禁止因"存量"静默消失；②本分支**恶化**了存量问题（扩大暴露面、删除防护）的按本分支缺陷计；③归责必须给 blame/log 实证，拿不到就按本分支保守计。
