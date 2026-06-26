---
id: baseline/secrets-in-code
pack: baseline
type: finding
dimension: security
severity: P0
enabled: true
applies_to: {}
summary: 硬编码的密钥/令牌/密码/证书进入代码或配置
---

## 识别要点
- diff 中出现疑似密钥/令牌/密码/私钥/连接串明文（`AKIA...`、`-----BEGIN ... PRIVATE KEY-----`、`password=`、`token=`、长 base64/hex 常量赋给 secret/key 命名的变量）。
- 提交进版本库的 `.env`、凭证 json、keystore。

## 取证方式
- 给出 `file:line` 与变量名/上下文；区分"真实凭证"与"占位符/示例"（占位符不报，标注判断依据）。
- 可疑但不确定真伪时标"待人工确认（是否为真实凭证）"。

## 修法
- 移到配置中心/环境变量/密钥管理；轮换已泄露凭证；从历史中清除。
