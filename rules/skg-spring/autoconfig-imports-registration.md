---
id: skg-spring/autoconfig-imports-registration
pack: skg-spring
type: finding
dimension: design
severity: P0
enabled: true
applies_to:
  languages: [java]
  frameworks: [spring]
summary: common-* 模块无 @ComponentScan，新增需 Spring 管理的类必须登记到该模块 AutoConfiguration.imports，漏登记启动失败
---

## 识别要点
- diff 是否在任一 `common-*` 模块（core/redis/rocketmq/mybatis/satoken 等）新增了 `@Service`/`@Component`/`@Configuration`/`@ConfigurationProperties` 等需 Spring 管理的类。
- 对应模块 `src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` 是否同步加了该类全限定名。

## 取证方式
- 给出新增类 `file:line` 与该模块 imports 文件路径，比对类全限定名是否已在 imports 中。
- 注意范围：业务模块（非 common-*）由 `@SpringBootApplication` 自身包扫描覆盖，不在此列；只对 common-* 新增类报。
- 漏登记后果：运行期 `NoSuchBeanDefinitionException` / APPLICATION FAILED TO START（运维视角硬阻塞，曾因削峰新增 4 个类漏登记导致启动失败）。

## 修法
- 把新增类全限定名补进该 common 模块的 `AutoConfiguration.imports`。
- 若类本应由业务模块扫描，确认它放对了模块；不要在业务侧加 `@ComponentScan` 兜底 common 包。
