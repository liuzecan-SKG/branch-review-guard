---
id: discover-new/pii-otp-plaintext-in-log
pack: discover-new
type: finding
dimension: security
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
  paths: ["**/*.java"]
summary: 验证码 OTP / 手机号 / 邮箱等 PII 明文打入日志，或生产类残留 main/测试方法里写死真实手机号/邮箱
---

## 识别要点
- `log.info` / `log.error` / `log.debug` 的占位符或字符串拼接里出现：验证码变量（verifyCode/code/smsCode/otp）、完整手机号（phone/mobile/account）、邮箱、身份证、紧急联系人。
- 生产实现类里残留 `public static void main` / `testXxx` 方法，方法体含真实手机号 / 邮箱 / AES 密钥 / 密文。
- 异常消息里带 URL 含 secret/token（如 RestTemplate 抛出的 URL 展开异常被 log 吞）。
- 与 baseline `secrets-in-code`（密钥/令牌/密码/证书）互补：本规则针对 **业务 PII 与一次性凭据（OTP）**。

## 取证方式
- grep 日志语句中的验证码/手机号变量名；确认无脱敏（如 `maskPhone(phone)` / 只打后 4 位）。
- 确认变量确实承载明文（不是已脱敏值）。
- 对 main/test 方法：确认类是生产类（在 src/main、非 @Test、被打包），且字面量是真实可用的手机号/邮箱/密钥（非明显假数据如 13800000000）。

## 修法
- 删除验证码明文打印；手机号/邮箱统一过脱敏工具（保留前 3 后 4 或地区码 + 后 4）。
- 移除生产类中的 `main` / `testXxx` 方法；真实测试数据迁到 src/test，密钥走 Nacos/环境变量。
- 异常 log 对含 secret/token 的消息先掩码。
- 已落库的明文日志/凭据需轮换。
