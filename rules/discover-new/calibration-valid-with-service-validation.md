---
id: discover-new/calibration-valid-with-service-validation
pack: discover-new
type: calibration
dimension: design
severity: "-"
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
summary: Controller 端点缺 @Valid，但其请求 DTO 本就无 bean-validation 约束、且 service 层已显式校验并抛业务码时，补 @Valid 是空操作 → 不计缺陷，至多 Nit
---

## 识别要点

- 发现形如：某 Controller 端点的 `@RequestBody` 参数缺 `@Valid`（相比同类端点不一致），据此判"入参校验缺失/校验不生效"。
- 需同时核对两件事，缺一不可轻判：
  1. 该请求 **DTO 字段是否真带 bean-validation 约束**（`@NotBlank`/`@NotNull`/`@Length`/`@Pattern` 等）——只有 `@Schema` 等文档注解、无约束注解时，`@Valid` 无任何可触发的约束。
  2. **service 层是否已对同名字段显式校验**（如 `if (StrUtil.isBlank(dto.getX())) ResultCode.XXX.throwing();` + 手机号/邮箱格式校验）。

## 校准动作

- 当"DTO 无 bean-validation 约束" **且** "service 层已显式校验并抛业务码"两条同时成立时：Controller 缺 `@Valid` 属**空操作层面的不一致**，**不计正确性/安全缺陷**，不进阻塞清单。
- 至多作为 **Nit**（"校验风格不统一，可考虑迁移到注解式声明校验"），且明确指出：单补 `@Valid` 而不给 DTO 加约束注解**不能改变任何行为**，不是有效修复。
- 本项目多处端点即采用"service 层显式 `if` 校验 + `ResultCode.xxx.throwing()`"的一致范式，属既定风格，不应逐个按"缺 @Valid"计缺陷。

## 豁免边界（以下不豁免，照常判定）

- **DTO 确有** `@NotBlank`/`@NotNull` 等约束，却因 Controller 缺 `@Valid`（或集合字段缺级联 `@Valid`）导致约束**不生效** → 这是真缺陷，按 correctness/api 报（参见 skg-spring/data-collect-protocol 的 `@Valid` 级联缺失）。
- DTO 无约束 **且** service 层也**未**显式校验该字段 → 是真正的"入参零校验"，按缺陷报（非法入参可直达业务/入库）。
- 涉及 C 端安全边界（越权/注入面）的入参校验缺失，仍按 security 维度严判，不因本校准放松。
