# Endpoint Performance Review

单接口 / Service 的性能复盘 skill：**证据优先**、**栈无关**，可挂载**可插拔规则**做栈特有深度检查。

## 用途

需求开发完成后，或被要求 review / 优化某个接口性能时，对单个后端接口（入口 + Service + 远程/DB/缓存 链路）做基于证据的复盘：先数清单次请求的真实调用数、区分冷/热缓存最坏情况，再按口诀提出按 P0/P1/P2 排序的优化，产出一份中文报告。

口诀：**先量化 → 砍多余 → 批量化 → 缓存 → 并发降级 → 特殊路径 → 测正确 → 留观测**。

## 与 branch-review-guard 的关系

本 skill 是 branch-review-guard 套件的**依赖**，被其整分支综合评审的"性能"维度（`SKILL.md` 第 6 章）复用——综合评审不重复实现性能分析，直接调用本 skill。也可脱离套件单独使用：只想优化某个接口时直接调它即可。

## 栈无关 + 可插拔规则

核心 checklist 栈无关。机制级深度（分布式锁 key、框架事务边界、RPC 专用池 / 超时、特殊数据回源等）外置到套件的 `rules/` 包：运行时加载 `rules/config.yaml` 里 `enabled` 包中 `dimension: performance` / `correctness` 且匹配当前仓库的规则，叠加做深度检查；未启用任何栈包时只跑通用 checklist（预期降级，不报错）。机制详见 `rules/README.md`。

## 用法

```text
/endpoint-perf-review <ControllerPath> <ApiPath>
/endpoint-perf-review <ServiceMethod>     # 如 OrderService.getOrderDetail
```

完整工作流、规则加载与报告模板见 `SKILL.md`。
