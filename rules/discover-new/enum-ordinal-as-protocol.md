---
id: discover-new/enum-ordinal-as-protocol
pack: discover-new
type: finding
dimension: design
severity: P2
enabled: true
applies_to:
  languages: [java]
  paths: ["**/*.java"]
summary: 值集不同源——用 enum.ordinal() 作外部协议、跨模块手写常量镜像枚举、校验器/分支硬编码值列表与枚举定义脱节，枚举演进（重排/加值）即静默错位或误判
---

> 2026-07-20 distill 第 0 期修订：新增 3 个"硬编码值集与枚举不同源"实例（AuthClientConfigValidator 硬列 3 个 APP 端值与 AppClientType 脱节、IAuthStrategy 硬编码 refreshToken 仅支持 APP_USER 与配置/文档三方矛盾、HEART_BRAIN_MEDICAL_NAMES 硬编码迁移后编码），累计 ≥5 实例，**解除"观察中"，视为稳固规则**。

## 识别要点
- `someEnum.ordinal()` 出现在校验/边界判定（如 `if (type < 0 || type > XType.values().length)`）。
- 跨模块/跨服务手写一个魔法常量（如某 `XXX_TAG = 1`）并注释"对齐某 XEnum 的 ordinal"。
- **硬编码值集与枚举/配置不同源**：校验器、白名单、分支逻辑里手写值列表（`List.of(3,2,6,10)`、硬列三个枚举名），而权威定义在别处的枚举/配置中——枚举加新值时校验器误报"非法"，或分支漏掉新值静默走错路径。
- 共同点：**取值正确性依赖两处定义人肉保持同步**，无编译期保障。

## 取证方式
- 确认 ordinal 被用于外部协议（接口入参/出参、DB 列、缓存值、跨服务对齐常量），而非纯内存遍历。
- 确认枚举存在中插风险（无 `@JsonValue` 显式 code、无锁定声明顺序的约定）。
- 判真伪：若该枚举已显式定义稳定 `code` 字段并以其持久化/传输，且魔法常量引用的是 code 而非 ordinal，则不命中。

## 修法
- 枚举显式定义稳定 `code`（int 或 string），持久化/传输一律用 code；跨模块共享的枚举迁到 `remote-*` 契约模块暴露。
- 魔法常量改为引用该枚举的 code（`XEnum.FAKE.getCode()`），删除手写镜像。
- 入参合法区间用显式白名单校验，不用 `ordinal()` 当上界。
- 硬编码值集改为从权威枚举派生（`Arrays.stream(XEnum.values())...` 或枚举上加能力字段/方法），单一定义点；确实要固化快照的（如迁移期编码），注释写明与哪个权威源对齐、何时可删。
