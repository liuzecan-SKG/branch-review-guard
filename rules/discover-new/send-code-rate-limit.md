---
id: discover-new/send-code-rate-limit
pack: discover-new
type: finding
dimension: security
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
  paths: ["**/*.java"]
summary: 发码/短信入口缺频控（60s 间隔被注释移除、无日上限、无 IP 维度、无 captcha），导致短信轰炸与注册枚举
---

## 识别要点
- 任意发送验证码/短信/邮件的入口（sendCode / sendVerifyCode / sendSmsCode / wxappPhoneSendCode 等触发下发）：方法体或拦截链中缺少以下任一即可疑：
  - per-account/per-mobile 的发送间隔（如 60s）与每日上限；
  - IP 维度限流（`@RateLimiter` 或等价）；
  - 图形/行为验证码门槛。
- 信号：原本的频控代码被大段注释掉（`// if (now - last < 60_000)`）；或频控计数 key 无 TTL；或验证码兜底硬编码（如 `666666`）。
- 配套缺陷：目标账号 DTO 仅 `@NotBlank` 无格式/长度校验 → 可对任意号码触发下发。

## 取证方式
- 沿"发送"调用链确认是否存在发送间隔 + 日上限 + IP 维度三层中至少前两层。
- 确认注释掉的频控确实是"移除"而非"挪到别处"（grep 同 key 是否仍被写）。
- 确认账号枚举面：未注册号是否不落库 + 响应可区分（响应体最小化、NOT_EXIST/INACTIVE 同构）。

## 修法
- 恢复 per-account 60s 间隔 + 每日上限；加 IP 维度 `@RateLimiter`；接入图形/行为验证码（且远程核验禁止 fail-open）。
- 频控计数 key 用 `incrAtomicAndExpire`，保证 TTL 到点自动失效。
- 移除硬编码兜底验证码；失败计数 key 加 TTL。
- 目标账号 DTO 按账户类型补格式+长度校验，下发前拦截任意号码。
- 豁免边界：内部/运维触发的不面向 C 端的下发接口不适用本规则。
