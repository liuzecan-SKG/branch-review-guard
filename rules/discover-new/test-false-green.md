---
id: discover-new/test-false-green
pack: discover-new
type: finding
dimension: tests
severity: P1
enabled: false
applies_to:
  languages: [java]
  frameworks: [maven, junit]
  paths: ["**/*Test.java", "**/pom.xml"]
summary: 测试假绿三变体——缺 @Tag 被 surefire groups 静默跳过、groups 与 profile 口径脱节致多数 profile 零执行、坏测试阻断 testCompile 后拿 stale 绿报告当通过
---

## 识别要点

- 新增/改动的测试类缺 `@Tag("test")`，而父 pom surefire 配置了 `<groups>`（如 `${profiles.active}`）——该测试在任何过滤 profile 下静默不执行。
- surefire `<groups>` 绑定 profile 变量时，核对可取值集合里有几个能命中 `@Tag` 值——只有一个命中即"其余 profile 下 CI 零业务测试"。
- staged/untracked 测试引用当前分支不存在的生产符号 → `testCompile` 失败会连坐同模块所有测试；此时 target/ 下的历史 surefire 报告是 stale 残留，"看到绿色报告"≠"本次执行过"。

## 取证方式

- 对新增测试类逐个核对 `@Tag` 注解存在性（DLP 环境用 Read，不用 grep 计数）；对照父 pom `<groups>` 配置原文给 file:line。
- 有条件时实跑一次 `mvn -P <目标profile> test`，以 `Tests run: N` 的 N 取证，不以 BUILD SUCCESS 取证。
- 判"测试已覆盖"前先确认构建链现时可编译（testCompile 通过），否则标"未被机器验证"。

## 修法

- 新测试类一律带 `@Tag("test")`（或项目 groups 约定值）；提交前跑一次带 groups 过滤的目标 profile 验证 `Tests run > 0`。
- 根治：父 pom 统一管理 test 依赖与 groups 口径，避免 groups 变量与 @Tag 值集脱节。
