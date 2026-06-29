# 样例：branch-review-guard 报告（示意，非真实评审结论）

> 本文件是**格式样例**，用于演示报告形态与可信度护栏。其中的功能、文件路径与 findings **均为构造示例**，不绑定任何具体框架，也不代表对任何真实分支的结论。真实运行的报告生成在项目内 `branch-review-reports/`（或安装器路径的 `tools/branch-review-guard/reports/`）。

报告文件：[branch-review-guard-branch-a1b2c3d4e-20260626-1500.md](../reports/branch-review-guard-branch-a1b2c3d4e-20260626-1500.md)

# feature-coupon-redeem-v2 提测前综合代码评审报告

> 元数据：分支 `feature-coupon-redeem-v2` | base `master` | commit `a1b2c3d4e` | 生成时间 `2026-06-26 15:00` | 模式 `branch`

## 0. 结论先行

- **可发布性**：有条件通过（须先修 2 条 P1）
- **Top 风险**：
  - [P1] 优惠券核销"删旧记录 + 写新记录"未在同一事务，中途失败会产生半条数据 — `.../coupon/service/CouponRedeemService.java:142`
  - [P1] 按手机号查询用户接口未校验调用者与目标归属，信任前端传入的 userId — `.../user/controller/UserQueryController.java:88`
  - [P2] 订单详情页复用整页聚合 payload，冷缓存下远程调用偏多 — `.../order/service/OrderDetailService.java:210`
- **总体评价**：分层与契约整体清晰，核销链路的事务边界与越权校验是主要待加固点。

## 1. 评审范围与方法

- 模式 `branch`；diff 口径 `git diff origin/master...HEAD`
- 变更文件数：源码 48（已按语言惯例排除测试文件）；其它（迁移脚本、`*.md`、依赖清单）若干
- 分批：按模块切 3 批（coupon / order / user），每批 12-20 文件，子代理并行
- 自动化先行：编译/构建 通过 / 单测 未运行（环境缺依赖，已跳过）/ 依赖扫描 未配置
- 已启用规则包：`baseline`（未启用任何栈包，故第 4 章只列通用高风险类别）
- 复用（弹性解析）：`api-change-guard`（影响/兼容/回归，已安装）、`endpoint-perf-review`（order/coupon 高风险入口，已安装）

## 2. 变更概览

- coupon：新增"优惠券二次核销"流程，支持核销撤销与重核销。
- order：下单时联动核销优惠券，订单详情新增优惠明细字段。
- user：新增按手机号查询用户（供客服侧使用）。

## 3. 分维度发现

### 3.1 正确性 / Bug

- [P1] 正确性 — 核销撤销 delete 旧记录 + insert 新记录未在同一事务，中途失败非原子 — `.../coupon/service/CouponRedeemService.java:142` — 失败时旧记录已删、新记录未写 → 数据丢失 — 用同一事务包裹两步写，或改为状态翻转的单条更新。
- [P2] 正确性 — 库存扣减 check-then-act 无锁，高并发下可能超卖 — `.../order/service/StockService.java:96` — 边界并发 — 加乐观锁(version) 或分布式锁，并确认锁 key 随 skuId 变化。

### 3.2 设计与代码质量

- [P2] 设计 — 订单详情页复用整个聚合 payload，取了页面不展示的字段 — `.../order/service/OrderDetailService.java:210` — 维护与性能成本 — 抽取窄查询路径，详见第 6 章。
- [Nit] 质量 — 金额格式化逻辑在 3 处重复 — `.../common/util/MoneyFormatUtils.java` — 漂移风险 — 收口到单一工具方法。

### 3.3 安全

- [P1] 安全 — 按手机号查询用户未校验调用者身份与目标归属，疑似信任前端传入的 userId — `.../user/controller/UserQueryController.java:88` — 横向越权查询他人信息（PII） — 服务端从会话/令牌上下文取当前用户并校验权限/归属。
- [待人工确认] 安全 — 第三方支付回调的签名校验是否在上游网关完成 — `.../order/controller/PayCallbackController.java` — 需确认上游是否已校验。

### 3.4 测试

- [P1] 测试 — 核销撤销事务原子性无针对性用例 — `CouponRedeemServiceTest`（缺失） — 高风险逻辑零覆盖 — 补"中途失败回滚"用例。

## 4. 高风险专题（由启用的规则包决定）

> 本次仅启用 `baseline`，故只列通用高风险类别；若启用对应栈包，会补充该栈机制级专题（如特定事务/锁注解、装配登记、上报协议等）。

- 事务与原子性：`CouponRedeemService` 两步写非原子（见 3.1）。
- 并发与锁：库存扣减无锁（见 3.2）。
- 对外契约：订单详情新增优惠明细字段 `discountDetail`——见第 5 章兼容性。
- 数据迁移与配置：`coupon_redeem_log` 迁移脚本需确认可回滚与存量兼容。

## 5. API 与兼容性 / 影响与回归范围（对接 api-change-guard）

- 请求兼容性：核销接口新增传参 `redeemSource`，确认是否新增必填（老端兼容）。
- 返回兼容性：订单详情新增 `discountDetail`——老客户端应可忽略未知字段。
- 受影响已上线功能：下单、订单详情、优惠券列表。
- 必须回归：下单联动核销、核销撤销/重核销；建议回归：订单详情渲染。

## 6. 性能与可靠性（对接 endpoint-perf-review）

- `OrderDetailService` 详情页：冷缓存下远程/DB 调用偏多（复用整页聚合）。建议窄路径 + 复用已有缓存。
- ⚠ 需运行时验证项：上述接口 p99、核销日志查询的执行计划是否走索引、库存扣减并发竞态——需压测/真实计划确认，本报告不下"已通过"。

## 7. 测试评估

- 覆盖矩阵：优惠券 CRUD 有用例；核销撤销事务、越权校验缺用例（见 3.4）。

## 8. 可观测性与运维就绪

- [P2] 核销撤销关键分支缺 info 日志，排障困难 — 补带 userId/couponId 的关键节点日志。
- 上线依赖：新增 `coupon_redeem_log` 表，确认已在各环境建好且可回滚。

## 9. 国际化

- 优惠文案确认走 i18n key；本批未见硬编码语言文本（抽样）。

## 10. 阻塞项清单（Merge 前 must-fix）

- [P1] `CouponRedeemService.java:142` 事务原子性 — 同一事务包裹两步写或改单条状态更新。
- [P1] `UserQueryController.java:88` 越权校验 — 服务端取当前用户并校验归属。

## 11. 非阻塞改进 / Nit

- 金额格式化收口（Nit）。
- 做得好：核销流程拆分为可撤销/可重核销，状态机清晰；新增字段有接口文档注释。

## 12. 待人工确认项

- 支付回调签名是否在上游网关校验。
- 订单详情新增字段是否必填、老客户端版本是否会下发。

## 13. 分析覆盖范围与未覆盖风险

- 覆盖率：已深读 ~40 / 摘要 ~6 / 未读 ~2（共 48），约 96%。
- 未覆盖风险：少量深层泛型 DTO 与跨服务调用方需人工复核；消息消费方影响标待确认。
