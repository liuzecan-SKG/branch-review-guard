# discover-new 规则包（团队沉淀区）

本包收纳**本团队从评审实践中沉淀**的规则——来源是 `/branch-review-guard:distill`（从历史报告聚类）与 `/branch-review-guard:rule`（手动录入）产出的草稿，经人工确认后落库。与上游作者预置的 `skg-spring/` **解耦**：插件升级时两者互不覆盖，便于区分"作者预置 vs 我们实测沉淀"。

**默认关闭**，由 `rules/config.yaml` 控制启用；启用后，各维度 reviewer 在通用 checklist 之外叠加本包规则。

规则文件 schema、reviewer 如何消费、严重度校准见上级 `rules/README.md`。

## finding 规则（要查的问题）

| id | 维度 | 默认严重度 | 一句话 |
| --- | --- | --- | --- |
| _（待沉淀——`distill`/`rule` 确认后的规则填这里）_ | | | |

## calibration 规则（降噪/绕过）

| id | 维度 | 一句话 |
| --- | --- | --- |
| _（待沉淀——`distill`/`rule` 确认后的规则填这里）_ | |
