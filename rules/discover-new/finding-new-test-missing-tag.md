---
id: discover-new/finding-new-test-missing-tag
pack: discover-new
type: finding
dimension: tests
severity: P1
enabled: true
applies_to:
  languages: [java]
  frameworks: [maven, junit5]
  paths: ["**/src/test/**/*Test.java"]
summary: 新增测试类缺 @Tag 时，surefire <groups>${profiles.active}</groups> 白名单机制下任何 profile 都不执行（假绿）——评审应主动核对新测试是否带匹配的 @Tag
---

## 识别要点

- root `pom.xml` 的 surefire 配置为 `<groups>${profiles.active}</groups>`（JUnit Platform includeTags 白名单语义：只执行标签命中者，无标签/不命中一律排除）。
- 本次改动**新增的测试类**是否带 `@Tag(...)`，且该 tag 值能被某个实际使用的构建 profile 的 `profiles.active` 匹配（业务测试约定 `@Tag("test")`，对应 `-P test`）。
- 缺 `@Tag` 或 tag 值与任何 profile 都不匹配 → 该测试在所有 profile 的 `mvn test` 下**静默跳过**，写了等于没写（假绿）。

## 取证方式

- 给出新测试类 `file:line`、其 `@Tag` 注解（或指出缺失）、`@Test` 方法数。
- 对照 root `pom.xml` surefire `<groups>` 表达式与各 profile 的 `profiles.active` 取值，说明该测试在哪些 profile 下执行 / 不执行。
- 高危形态：鉴权/白名单类测试无 `@Tag` → 任何 profile 都不跑；此类假绿危害大，优先报。
- 注意：与"缺 JUnit5 engine 依赖致 `mvn test` 构建期爆雷"是**两个独立问题**（engine 缺失=硬失败，tag 过滤=软跳过），勿混淆。

## 修法

- 新测试类补一行 `@Tag("test")`（对齐项目既有测试约定与 import `org.junit.jupiter.api.Tag`）。
- 若项目多 profile 需跑不同测试集，确认 tag 值与目标 profile 的 `profiles.active` 对应。
