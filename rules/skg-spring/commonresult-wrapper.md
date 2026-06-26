---
id: skg-spring/commonresult-wrapper
pack: skg-spring
type: finding
dimension: api
severity: P2
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
summary: 对外接口统一返回 CommonResult<T>；改返回结构注意老客户端兼容
---

## 识别要点
- 新增/修改的 Controller 接口返回类型是否统一为 `CommonResult<T>`（成功/失败/错误码各路径都走）。
- 是否裸返回实体/Map/String，或绕过全局异常处理直接抛而不收口为 `CommonResult`。
- 既有接口的 `CommonResult` 内层结构（字段增删、改名、类型变化）是否变动。

## 取证方式
- 给出接口方法 `file:line` 与返回类型，与同模块同类接口对比一致性。
- 改返回结构时指出受影响端侧（APP/小程序/管理后台/设备上报），评估老客户端解析是否破坏（兼容性风险）。

## 修法
- 统一走 `CommonResult.success(...)` / `CommonResult.error(...)`，错误码用既有 `ErrorCode`。
- 返回结构变更优先**新增字段**而非改名/删字段；破坏性变更须与端侧约定版本并灰度。
