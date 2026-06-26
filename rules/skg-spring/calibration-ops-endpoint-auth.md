---
id: skg-spring/calibration-ops-endpoint-auth
pack: skg-spring
type: calibration
dimension: security
severity: "-"
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring, satoken]
summary: 运维/内部写接口（/admin/** 等）默认由网关/内网/IP 白名单/独立 admin 鉴权保护，缺 C 端用户级鉴权直接越过、不报告
---

## 识别要点
- 发现类是"运维/内部接口缺用户级鉴权"：`/admin/**` 迁移、`lock`/`reset`/`start`/`refresh` 等运维操作接口缺 `StpUtil` / `@SaCheckPermission`。

## 校准动作
- 这类接口默认由网关/内网/IP 白名单/独立 admin 鉴权保护，缺 C 端用户级鉴权属正常豁免，**直接越过、不报告**。
- 不计入 P0/P1，**也不列入待人工确认**。
- 不放松：**C 端用户接口**的越权、未校验登录态、信任前端 userId 仍按 satoken-auth-userid 严判。
- 边界：无法静态确认接口属 C 端还是运维/内部时，按 C 端从严判定并标"待人工确认"。
