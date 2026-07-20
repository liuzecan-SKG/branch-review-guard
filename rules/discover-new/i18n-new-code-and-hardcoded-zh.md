---
id: discover-new/i18n-new-code-and-hardcoded-zh
pack: discover-new
type: finding
dimension: observability
severity: P2
enabled: true
applies_to:
  languages: [java]
  paths: ["**/*.java", "**/messages*.properties"]
summary: 新增 C 端可见 ResultCode 未在全部 locale 补数字 key（海外 fallback 中文）；C 端兜底文案硬编码中文 / 取关系名写死 lang="zh"
---

## 识别要点
- `ResultCode`（或等价错误码枚举）新增码值，但 `messages_*.properties`（各 locale）没有对应数字 key。
- C 端可见字符串硬编码中文（`desc` / `getDesc` / 兜底 prompt），或取关系名/多语言名时写死 `"zh"` 而非从请求 lang 解析。
- 业务代码里裸中文常量散布（如 "已注销用户"）。
- 校验 key 只在部分 locale 补齐，其余文件填英文占位或缺省。

## 取证方式
- 对每个新 ResultCode 数字，grep 全部 `messages_*.properties` 是否都有该 key。
- 确认码是否 C 端可达（接口响应/前端展示），还是仅内部/运维可见（运维可见可降级）。
- 对硬编码中文：确认是否面向多区域（仅 cn-prod 则豁免，出海区不豁免）。
- 兜底链核实：确认是否真有 GlobalExceptionHandler + MessageUtils 兜底（决定严重度 P2 而非 P1）。

## 修法
- 为每个 C 端可见新码在全部 locale 补齐数字 key；建立"新增 ResultCode 必须同时补 key"的提交检查。
- 兜底文案走 MessageUtils / i18n key；关系名/多语言名用当前请求语言解析（如 `LocaleUtils.getLangCode(...)`），不写死 `"zh"`。
- 裸中文收口为常量 + i18n。
- 豁免边界：仅 cn-prod 的功能、纯运维可见码（已由 calibration 覆盖的运维接口文案）可降级。
