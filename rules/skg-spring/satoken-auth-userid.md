---
id: skg-spring/satoken-auth-userid
pack: skg-spring
type: finding
dimension: security
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, satoken]
summary: C 端接口用 StpUtil.getLoginIdAsLong() 取登录态，不信任前端传入 userId（横向越权）；写接口校验数据归属
---

## 识别要点
- C 端写接口/敏感读接口是否用前端传入的 `userId`/`uid` 作为操作主体，而非 `StpUtil.getLoginIdAsLong()`。
- 资源操作（改/删/查他人数据）前是否校验"该资源属于当前登录用户/租户"。
- 新增 C 端接口是否相比同模块同类接口遗漏 `StpUtil.checkLogin()` / 归属校验。

## 取证方式
- 给出接口 `file:line`，指出 userId 来源是请求参数还是登录态；若来自参数且无归属校验 → 横向越权（可改/查别人健康数据，PII）。
- 区分接口类型：**C 端接口**严判；运维/内部 `/admin/**` 接口缺用户级鉴权按 calibration-ops-endpoint-auth 越过，不在此报。
- 无法静态确认是否有上层网关/AOP 统一鉴权时，标"待人工确认"并指出需确认点。

## 修法
- 操作主体一律取 `StpUtil.getLoginIdAsLong()`；前端传的 userId 仅作过滤展示，写路径不可信任。
- 写/敏感读前校验资源归属（`resource.userId == 当前登录 id`），不属于则拒绝。
