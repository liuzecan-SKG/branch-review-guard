---
id: discover-new/declared-vs-actual-drift
pack: discover-new
type: finding
dimension: design
severity: P2
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
  paths: ["**/*.java"]
summary: 声明与实现脱节——注释/javadoc/命名/配置前缀承诺的行为与代码实际不符；轻则误导后人，重则静默失效（@ConfigurationProperties 前缀绑不上、命名叫 secure 实际明文）——后者升 P1
---

## 识别要点

- 四类声明逐一对照实现：①`@ConfigurationProperties`/`@Value` 前缀 vs javadoc/配置文件实际 key（绑不上=静默失效，P1）；②方法/路由命名承诺（secure/encrypt/masked）vs 是否真接线（注解缺失、死字段佐证半成品，P1）；③注释断言的异常兜底/一致性方向 vs 真实控制流（异步化后 catch 兜不住、"只会多判 null"只覆盖单方向）；④注释写的日志级别/行为 vs 实际调用。
- 死字段/死配置是"半成品接线"的强信号，顺藤摸声明与实现的缝。

## 取证方式

- 并排给出声明处与实现处两个 file:line，指出脱节点；静默失效类补一条"配置实际绑定验证"（能起容器验证最好，不能则标注需运行时验证，不写"已确认失效"）。

## 修法

- 改实现时同步改声明（注释/命名/javadoc），这是既有红线"改逻辑同步改注释/命名"的评审侧对应；前缀类统一以配置中心实际 key 为准回改代码。
- 命名承诺的能力（加密/脱敏）必须有机制佐证（注解生效、过滤器命中），接不上就改名，不留"叫 secure 的明文接口"。
