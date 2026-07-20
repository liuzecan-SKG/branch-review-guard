---
id: discover-new/c-end-dto-validation-gap
pack: discover-new
type: finding
dimension: correctness
severity: P2
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
  paths: ["**/*.java"]
summary: C 端 DTO 数值/格式字段仅 @NotBlank 或无约束，畸形输入直达业务层强解析抛 500/越界异常；Controller 漏 @Valid
---

## 识别要点
- C 端面向用户的请求 DTO（Dto 结尾、Controller 形参）字段：
  - 数值字段（如 countryCode/clientType/region）只用 `@NotBlank` 而无 `@Pattern(\d+)` / `@Range`，业务层再 `Integer.valueOf` / `values()[int]`；
  - 字符串字段（account/phone/mac/smsCode/nickname）无 `@Length` / `@Pattern` / `@Size`；
  - mac 地址无格式约束。
- Controller 形参未标 `@Valid` / `@Validated`，Bean 校验不触发。
- 业务层随后对原始字符串直接 `Integer.valueOf`、`EnumType.values()[int]`、`Long.parseLong` → 畸形输入抛 `NumberFormatException` / `ArrayIndexOutOfBoundsException` 直接 500。

## 取证方式
- 列出 DTO 中数值/受限格式字段，确认是否只有 `@NotBlank`。
- 跟踪字段被消费处：是否有未 try-catch 的强解析。
- 确认 Controller 入口有 `@Valid`；注意经 `BeanUtil.copyProperties` 转换的二次对象上原有约束注解不会被再次触发（校验只在 `@Valid` 入口那层生效）。

## 修法
- DTO 按字段语义补：`@Pattern`（数字/手机号/mac 正则）、`@Length`/`@Size`、`@Min/@Max`/`@Range`。
- Controller 形参统一加 `@Valid`；对经 BeanUtil 转换的二次对象也补校验或入口判空。
- 业务层强解析处补 `try-catch` 兜底，或改用返回 Optional 的安全解析。
- 豁免边界：内部/网关内调用的 DTO、明显非 C 端的接口可降级。若 DTO 无约束但 service 层已显式校验并抛业务码，则补 @Valid 属空操作（见 calibration-valid-with-service-validation）。
