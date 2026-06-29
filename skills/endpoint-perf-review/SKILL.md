---
name: endpoint-perf-review
version: 0.2.5
description: Review and optimize the performance of a single backend endpoint/interface (entry point + service + remote/DB/cache chain) in a stack-agnostic, evidence-first way, producing a prioritized findings report. Optionally loads stack-specific rules from the pluggable `rules/` packs for mechanism-level depth. Use when asked to review, optimize, refactor, or improve the performance of an API/interface/Service, or to do a post-development performance review.
---

# Endpoint Performance Review

需求开发完成后，用本 skill 对单个后端接口做性能复盘并给出优化方案。核心**栈无关**、**证据优先**：在提出任何优化前，先数清热路径上真实的 远程(RPC)/DB/缓存 调用数，并分析**冷缓存最坏情况**，而不只看 happy path。

本 skill 是 branch-review-guard 套件的依赖，被其整分支综合评审的"性能"维度（第 6 章）复用，不重复实现。

## Supported Commands

- `/endpoint-perf-review <ControllerPath> <ApiPath>`
- `/endpoint-perf-review <ServiceMethod>`（如 `OrderService.getOrderDetail`）

## Workflow

1. 定位入口（Controller / handler 方法）与主 Service 方法。
2. 追整条依赖链。链路宽/跨模块时，用并行子代理（若 Agent 支持）梳理：远程(RPC)调用、DB 查询、缓存访问、异步任务、共享 helper。
3. 为**单次请求**建调用清单：列出每个 远程/DB/缓存 调用，标注它是"缓存命中"还是"缓存未命中"成本，以及最终服务于哪个返回字段。
4. 把"热缓存成本"与"冷缓存最坏情况"分开（尾延迟通常出在冷缓存）。
5. 套用下面的 checklist；每条发现都附证据（file:line + 原因）与按优先级排序的修法（P0/P1/P2）。
6. 按下面模板输出中文报告。

## 加载栈特有规则（可选，深度检查）

本 skill 核心保持栈无关。若目标仓库随套件安装了可插拔规则（`rules/`），在跑通用 checklist 的同时：

1. **加载**：读 `rules/config.yaml` 中 `enabled: true` 的规则包。
2. **取规则**：选其中 `dimension: performance`（性能机制）与 `dimension: correctness`（优化引入的正确性风险，如改动了共享代码行为）、且 `applies_to` 匹配当前仓库（语言/框架/路径）的规则。
3. **机制级深度检查**：按每条规则的「识别要点 / 取证方式 / 修法」在热路径代码上找命中，命中按其 `severity` 计入发现项。
4. **缺包降级**：未启用任何栈包时，仅跑下面的通用 checklist —— 这是预期，不要因"没装某包"而报错。

> 例：Spring / RPC 框架 / ORM / 文档库 同栈，可启用对应规则包，获得"分布式锁 key、框架事务边界、RPC 专用池/超时"等机制级规则，无需把这些写死进核心 skill。规则机制详见 `rules/README.md`。

## Review Checklist（口诀：先量化 → 砍多余 → 批量化 → 缓存 → 并发降级 → 特殊路径 → 测正确 → 留观测）

- **先量化(基线)**：数清单次请求的 远程(RPC)/DB/缓存 调用数，定位热路径，对比热缓存 vs 冷缓存最坏情况。无基线不优化。
- **砍多余**：窄需求别复用重量级聚合（如单条详情页复用了整个首页大聚合）；去重复调用；不取返回里没用到的实体/字段。
- **批量化**：N+1；"全量加载再找单条"（拉全表/全列表只为定位一行）→ 改批量或定向单查；优先轻量投影方法而非重方法。
- **缓存**：复用已有缓存；静态配置进程内缓存；TTL 与空值（负）缓存；热点共享键（如被多 viewer 共享的演示/虚拟实体）做单飞/防击穿（必要时用分布式锁串行回源）；数据若由异步事件更新、新鲜度允许时，可加短 TTL 的响应缓存。
- **并发降级**：独立 I/O 并行，且用**专用有界线程池**（**勿**复用 scheduled / 公共池跑阻塞调用）；**显式传递请求上下文**（用户/租户/语言/时区等上下文默认**不跨线程**——提交任务前先捕获）；每个非关键调用失败可降级；收紧 RPC/HTTP 超时并配熔断。
- **特殊数据路径**：虚拟/演示/合成数据不要触发真实回源/写入路径（可能写出空壳）；用预置或幂等回填；确认写侧与读侧用的是同一套 key。
- **测正确**：优化窄路径时别改共享代码的行为——抽出有测试覆盖的共享内核；保住鉴权与幂等。
- **留观测**：加分阶段耗时/指标/日志以量化前后并防回归；对单行/热点查询跑 `EXPLAIN` 确认命中索引。

## Caveat

这是一份**提问清单**，不是必做项清单。过度缓存、过度并行会带来一致性与复杂度成本。每条都按"相对实测基线的 ROI"判断，不划算就跳过。

## Report Template（输出中文）

```markdown
# 接口性能 Review 报告：<接口/方法>

## 结论先行
<一句话：当前最大瓶颈 + 收益最高的 1-3 项优化>

## 调用清单（单次请求）
- <调用> | 远程/DB/缓存 | 命中/未命中成本 | 服务于哪个返回字段 | 是否必要
- ...
（区分：缓存命中路径 vs 冷启动最坏情况）

## 发现项（按优先级）
- [P0] <问题> — 证据：<file:line + 原因> — 方案：<怎么改>
- [P1] ...
- [P2] ...

## 推荐方案
<最优落地顺序，标注是否改动共享代码、是否跨模块、需要的测试>

## 风险与护栏
<行为变更确认、降级、超时、索引、并发上下文、观测埋点>
```
