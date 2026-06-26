# Changelog

本文件记录 Endpoint Performance Review 的版本变更，版本遵循语义化版本（SemVer）。

## [0.2.0] - 2026-06-26

### 变更
- **泛化为"栈无关 + 可插拔规则"的可发布版本**：把核心 checklist 与报告流程从具体技术栈解耦，作为 branch-review-guard 套件的依赖发布（被其综合评审"性能"维度复用）。
- 去具体栈词、改通用表述：`Dubbo` → 远程(RPC)调用；`Redis` → 缓存；`ThreadLocal` + 登录上下文 → "请求上下文（用户/租户/语言/时区）默认不跨线程，提交任务前显式捕获传递"；scheduled / 公共池 → "专用有界线程池而非公共池"；自研事务 / 分布式锁 / 虚拟用户回源等具体机制 → 通用描述（"框架事务边界""分布式锁防击穿""合成/演示数据不触发真实回源"）。
- frontmatter 增加 `version: 0.2.0`；`description` 去栈化、通用化。

### 新增
- 新增「加载栈特有规则」一节：跑通用 checklist 的同时，可加载 `rules/` 中 `dimension: performance` / `correctness` 且 `applies_to` 匹配当前仓库的规则做机制级深度检查；未启用任何栈包时降级为只跑通用 checklist（预期，不报错）。
- 配套通用版 `cursor-rules/endpoint-perf-review.mdc`（Cursor 提醒规则）与 `README.md`。

### 保留
- 栈无关核心不变：证据优先方法（先量化调用清单 → 砍多余 → 批量化 → 缓存 → 并发降级 → 特殊路径 → 测正确 → 留观测）、冷/热缓存最坏情况区分、`EXPLAIN` 等通用 DB 手段、口诀、报告模板（结论先行 / 调用清单 / 发现项 P0/P1/P2 / 推荐方案 / 风险与护栏）、以及"这是提问清单不是必做项，按 ROI 取舍"的取舍原则。

### 说明
- 运行时维度（真实 RT/p99、并发竞态、降级/熔断真实行为）只输出"需运行时验证项"，静态评审不下"已验证通过"结论（与套件 `rules/baseline/runtime-claims-need-evidence` 一致）。
