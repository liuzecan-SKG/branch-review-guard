# Changelog

本文件记录 Branch Review Guard 的演进。

## [0.2.1] - 2026-06-29

### Added

- **Claude Code 原生插件封装（叠加，不影响通用安装器）**：仓库新增 `.claude-plugin/`（`plugin.json` + 单插件 `marketplace.json`，`source: "./"`），使其可经 `/plugin marketplace add liuzecan-SKG/branch-review-guard` + `/plugin install branch-review-guard@branch-review-guard` 一键安装、启停、按 `version` 迭代、部门内复用。`skills/` 与 `rules/` 内核与原通用安装器（`manifest.json`）**共享同一份**，两种封装出口共存。
- **`/branch-review-guard` slash 命令**（`commands/branch-review-guard.md`）：解析 `branch|diff|recent|module` 与 `--base/--dimensions`，委派 `branch-review-guard` skill 执行。
- **5 个只读维度子代理**（`agents/bru-*.md`）：`bru-correctness`、`bru-design`、`bru-security`、`bru-tests`、`bru-observability`。编排器在 Claude Code 插件形态下按批并行派发，上下文隔离；不支持子代理的环境自动回退顺序多轮。各子代理以对应 `prompts/review-*.md` 为权威清单并内置回退清单 + `rules/` 加载约定。
- `orchestrate-branch-review.md` 第 6 步补充：插件形态优先派发上述命名子代理。

### Fixed

- **复用依赖 skill 的插件形态感知**：原先复用 `api-change-guard` / `endpoint-perf-review` 仅按文件路径（`tools/` → `.cursor/` → `.claude/`）解析；纯插件形态下这些路径不存在会误降级为"未安装"。现增加优先分支：作为 Claude Code 插件运行时，这两个依赖随插件一同加载，**直接以 skill 形式调用**（`branch-review-guard:<name>`），不再因路径缺失误判未覆盖。改动 `SKILL.md` `## 评审维度与复用映射` 与 `orchestrate-branch-review.md` 第 7 步。

### Notes

- 本次为 v0.2 线内的**叠加式**小版本：默认 `branch` 全量评审行为、规则机制、L1/L2/L3 诚实护栏均不变；`manifest.json` / `plugin.json` 同步至 `0.2.1`。

## [0.2.0] - 2026-06-26

### Changed

- **泛化为栈无关 + 可插拔规则**：核心 skill 不再内联任何技术栈的特有坑（如特定事务/锁注解、框架装配登记、特定工具类/鉴权 API、设备上报协议等）；这些全部**外置到 `rules/` 规则包**（`baseline` 默认开 + 可选栈包如 `skg-spring`）。各维度 reviewer 改为"通用 checklist + 运行时加载本维度已启用规则"。
- **误报校准外置**：原内联的"项目惯例降噪"规则改由 `rules/` 中 `type: calibration` 规则提供；`SKILL.md` 的 `## 误报校准` 改为 `## 校准规则（降噪，由 rules/ 提供）`，不再内联具体团队惯例。
- **弹性路径解析（修复硬编码 bug）**：复用 `api-change-guard` / `endpoint-perf-review` 时，按 `tools/<name>/SKILL.md` → `.cursor/skills/<name>/SKILL.md` → `.claude/skills/<name>/SKILL.md` 顺序查找；找不到则该维度降级并在报告对应章节声明"依赖未安装、该维度未覆盖"。修复了原文硬编码 `tools/endpoint-perf-review/SKILL.md` 的问题。
- **Git/自动化命令栈无关化**：`git diff` 不再写死 `*.java` 过滤、L1 自动化改为"按项目工具链"（编译/构建/lint/测试/SCA），测试排除按多语言惯例。
- **报告模板/示例泛化**：第 4 章"高风险专题"改为"由启用的规则包决定（如事务/并发/对外契约/数据迁移）"，不再写死具体注解名；示例报告改为栈无关示意（明确标注"示意，非真实结论"）。

### Added

- `SKILL.md` 新增 `## 规则机制（栈无关核心 + 可插拔规则包）`：说明 baseline 默认开、栈包可选、缺包降级（通用 checklist 照跑）、reviewer 按 `dimension` + `applies_to` 消费 finding/calibration 规则。
- `SKILL.md` frontmatter 新增 `version: 0.2.0`。

## [0.1.2] - 2026-06-26

### Changed

- 误报校准规则由"降级为待人工确认"改为**直接越过、不报告**：项目惯例类降噪（如某些配置/迁移不在代码仓库、运维/内部写接口默认豁免 C 端用户级鉴权）**既不计 P0/P1，也不列入待人工确认**。降噪更彻底，对外/C 端越权与真实逻辑缺陷判定不变。
- （注：这些项目惯例校准在 0.2.0 已外置到 `rules/` 规则包，不再内联。）

## [0.1.1] - 2026-06-24

### Changed

- 新增**误报校准（项目惯例，降噪）**机制，降低真实评审中被误报为 P1 的噪声；该校准只降噪，不放松对外/C 端接口与真实缺陷的判定。
- （注：0.2.0 已把这些校准外置为 `rules/` 中 `type: calibration` 的规则条目。）

## [0.1.0] - 2026-06-24

### Added

- 初版 MVP：提测/上线前整分支综合评审编排器。
- 正本 `SKILL.md`：编排工作流、base 探测与多种分析模式（branch/diff/recent/module）、大 diff 强制分批全覆盖、可移植双模式（子代理并行 / 顺序多轮）、自动化分级护栏（L1/L2/L3）、报告结构与回复约定。
- `prompts/`：`orchestrate-branch-review`、`review-correctness`、`review-design`、`review-security`、`review-tests`、`review-observability`、`consolidate-report`。
- `templates/report-template.md` 与 `examples/sample-branch-review-report.md`。
- 维度复用映射：API/兼容/影响/回归复用 `api-change-guard`，性能复用 `endpoint-perf-review`，不重复实现。
- 各维度判定 grounded 于项目特有机制（彼时内联在 prompts，0.2.0 已外置到 `rules/`）。
- `SKILL.md` 镜像到 `.cursor/skills/` 与 `.claude/skills/`；新增 `.cursor/rules/branch-review-guard.mdc` 提醒规则。

### Notes

- 运行时维度（性能 p99、并发竞态、迁移在存量数据下表现）只输出"需运行时验证项"，不下"已验证通过"结论。
