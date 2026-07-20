---
id: discover-new/external-http-no-timeout
pack: discover-new
type: finding
dimension: observability
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
  paths: ["**/*.java"]
summary: 外部 HTTP 依赖（第三方 RestTemplate、SDK 客户端）无 connect/read timeout，慢响应拖死线程；聚合页多路下游 Dubbo 沿用默认超时
---

## 识别要点
- `new RestTemplate()` 直接构造且未设 `setConnectTimeout` / `setReadTimeout`（或用默认 SimpleClientHttpRequestFactory 无连接池）。
- 自建/SDK 的 HTTP 客户端（OkHttp/Apache HttpClient/第三方云 SDK）未配置超时。
- `@DubboReference` 在聚合/编排路径未指定 `timeout`，沿用默认（1s 或更高），慢依赖耗尽请求线程。
- 高并发入口（首页聚合、登录、取号、验证码核验）调用上述外部依赖。

## 取证方式
- 确认客户端构造处无超时设置；确认无全局 RestTemplate Bean 统一注入超时。
- 估算最坏阻塞：是否有 single-flight/惊群直刷叠加使单请求等待时间成倍放大。
- Dubbo 聚合路径：确认每个下游 `@DubboReference` 是否显式 `timeout`，以及是否配套 per-call try/catch 局部降级。

## 修法
- 复用项目统一 RestTemplate Bean；显式设超时（建议 connect=3s/read=5s），评估 `HttpComponentsClientHttpRequestFactory` 连接池。
- 第三方 SDK/客户端按依赖重要性分别设超时（取号/验证码 2~3s）。
- 聚合页每路下游显式 `timeout` ≤ 编排总预算；非关键下游 try/catch 局部降级，避免单路慢拖垮整页。
- 超时值挪到 Properties/Nacos 以适配多区域网络差异。
