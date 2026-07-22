# discover-new 规则包（团队沉淀区）

本包收纳**本团队从评审实践中沉淀**的规则——来源是 `/branch-review-guard:distill`（从历史报告聚类）与 `/branch-review-guard:rule`（手动录入）产出的草稿，经人工确认后**先落目标项目本地 `branch-review-rules/` 试用**（`pack: local`），本地服役命中 ≥3 且存活率 ≥2/3 才**晋升**进本包（两段式落位，见 `rules/README.md`「规则生命周期与目录规范」）。**本包空是常态、不是欠账**。与上游作者预置的 `skg-spring/` **解耦**：插件升级时两者互不覆盖，便于区分"作者预置 vs 我们实测沉淀"。

由 `rules/config.yaml` 控制启用（v0.8.0 起默认开）；启用后，各维度 reviewer 在通用 checklist 之外叠加本包规则。

规则文件 schema、reviewer 如何消费、严重度校准见上级 `rules/README.md`。

> **首批装载（v0.8.0，2026-07-20）**：19 条（16 finding + 3 calibration），来自 skg_health_global 在项目本地 `branch-review-rules/` 服役的实测规则，经证据实例聚类与人工分档后晋升（详见 `skills/branch-review-guard/CHANGELOG.md` 0.8.0 节）。留在项目本地未晋升的：3 条主观/绑定型（`god-service-overload` 偏主观、`calibration-javax-resource-injection` 绑栈现状、`calibration-minimal-ladder-alignment` 绑方法论）+ 3 条个人工作区特例。
>
> **补录 4 条（2026-07-21）**：`calibration-repo-ddl-not-baseline`、`calibration-dead-defense-null-branch`、`calibration-dependency-attribution-by-review-mode`、`finding-new-test-missing-tag`。这 4 条此前**只存在于插件缓存、未入库**（缓存在机器级、多 clone 共享，改缓存能立刻生效，于是绕过了入库），实测生效但重装即失、无版本控制。本次回收入库补齐版本控制。**教训**：规则的事实来源是仓库，缓存只是分发副本——用 `scripts/sync-plugin-cache.sh check` 定期查分叉。
>
> **开关修复（2026-07-21）**：首批 19 条里有 8 条 `enabled: false`（晋升时只搬了文件、没开开关），实际生效仅 11 条。已全部置 true。**规则进了库不等于进了作用域**，`enabled` 是晋升的第 0 步。

## finding 规则（要查的问题）

| id | 维度 | 默认严重度 | 一句话 |
| --- | --- | --- | --- |
| `discover-new/txn-external-side-effects-after-commit` | correctness | P1 | Spring `@Transactional` 内发 MQ / Dubbo RPC / 删 Redis，DB 回滚后外部副作用不可撤销 |
| `discover-new/token-check-then-act-race` | correctness | P1 | 一次性令牌 check-then-act 无锁无唯一索引，并发/重试重复落库或夺绑 |
| `discover-new/multi-step-write-no-compensation` | correctness | P1 | 跨服务/跨存储多步写缺顺序与补偿，后步失败留孤儿或幂等短路阻自愈 |
| `discover-new/schema-evolution-migration-gap` | correctness | P1 | 新列/新哨兵值无存量回填迁移，老数据落危险分支或"存在行=已填写"语义被击穿 |
| `discover-new/cache-truth-and-lifecycle` | correctness | P1 | 缓存当唯一真相源 / 负缓存无 TTL / 失效靠单条 MQ / 加字段惊群 四形态 |
| `discover-new/c-end-dto-validation-gap` | correctness | P2 | C 端 DTO 数值字段仅 `@NotBlank`，畸形输入直达业务层抛 500；Controller 漏 `@Valid` |
| `discover-new/pii-otp-plaintext-in-log` | security | P1 | 验证码/手机号/邮箱等 PII 明文入日志，或生产类残留写死真实号码 |
| `discover-new/send-code-rate-limit` | security | P1 | 发码入口缺频控（间隔/日上限/IP/captcha），短信轰炸与注册枚举 |
| `discover-new/loop-remote-call-nplus1` | performance | P1 | 循环/forEach 内单条 Dubbo/远程调用构成真 N+1 |
| `discover-new/external-http-no-timeout` | observability | P1 | 外部 HTTP/SDK 无 connect/read 超时，慢响应拖死线程 |
| `discover-new/i18n-new-code-and-hardcoded-zh` | observability | P2 | 新增 C 端 ResultCode 未补全 locale 键；兜底文案硬编码中文 / 写死 lang="zh" |
| `discover-new/aggregation-degradation-blindspot` | observability | P2 | 聚合/降级路径三查：catch 粒度连坐、降级对称性、指标可观测 |
| `discover-new/test-false-green` | tests | P1 | 测试假绿三变体：缺 `@Tag` 被 surefire groups 跳过 / groups 与 profile 脱节 / 坏测试拿 stale 绿报告 |
| `discover-new/declared-vs-actual-drift` | design | P2 | 注释/命名/配置前缀承诺与实现脱节，重则静默失效（升 P1） |
| `discover-new/enum-ordinal-as-protocol` | design | P2 | 值集不同源：ordinal 当外部协议 / 硬编码值集与枚举脱节，演进即错位 |
| `discover-new/shotgun-duplicate-logic` | design | P2 | 同构逻辑/工具方法跨类逐字复制，改一处要动多处 |
| `discover-new/finding-new-test-missing-tag` | tests | P1 | 新增测试类缺 `@Tag` 时 surefire `<groups>` 白名单下任何 profile 都不执行（假绿） |

## calibration 规则（降噪/绕过）

| id | 维度 | 一句话 |
| --- | --- | --- |
| `discover-new/calibration-reachability-and-defense-in-depth` | correctness | 定 P0/P1 前核实触发路径可达性 + 下游/全局防线，降本项目最高频误报 |
| `discover-new/calibration-baseline-attribution` | correctness | 报缺陷前 git blame 基线归责，存量老债不算本分支；但高危存量须显式转交 |
| `discover-new/calibration-valid-with-service-validation` | design | Controller 缺 `@Valid` 但 DTO 无约束且 service 已校验时补它是空操作，不计缺陷 |
| `discover-new/calibration-repo-ddl-not-baseline` | correctness | 仓内 `*.sql` 是旧快照，不得作为"缺索引/缺约束"的静态定级基准，统一降"待人工确认（对照线上表）" |
| `discover-new/calibration-dead-defense-null-branch` | correctness | 报"判空缺失/null 绕过"前先追来源方法全部 return 路径；恒非 null 则是死防御，不报缺陷 |
| `discover-new/calibration-dependency-attribution-by-review-mode` | design | pom/依赖类发现先按当前评审口径核归属，master 既有依赖不得报为"本次新增" |
