# Changelog

本文件记录 Branch Review Guard 的演进。

## [0.2.8] - 2026-06-29

### Changed

- **README 介绍段重写为亮点分点**：顶部介绍精简为"一句定位 + 6 条带 emoji 的差异化要点"（整分支强制全覆盖 / 多维并行 + 5 子代理 / 可发布性裁决 / 诚实边界 / 可插拔规则 / 一键启停·版本·复用），去掉与 PR 工具的对比段，更突出插件亮点与差异化。plugin/manifest → 0.2.8。

## [0.2.7] - 2026-06-29

### Changed

- **更新生效方式改为 `Developer: Restart Extension Host`**：实测 VSCode 扩展里 `Reload Window` 往往不足以重载插件（常驻 agent 会话未重置），且 `/reload-plugins`、`/restart-agent` 命令不可用。README 移除 `Reload Window` 指引，统一改为 `Ctrl+Shift+P → Developer: Restart Extension Host`（重启扩展宿主，比整体重启 VS Code 轻），并在「更新」节加"让更新/配置变更生效"说明。
- plugin.json / manifest.json 版本 `0.2.6` → `0.2.7`（交付该文档更新）。

## [0.2.6] - 2026-06-29

### Changed

- **斜杠命令规范化为 `/branch-review-guard:review`**：Claude Code 插件命令带命名空间 `<插件名>:<命令名>`，原命令文件名 `branch-review-guard.md` 会得到难看且报 Unknown 的裸 `/branch-review-guard`（实为 `/branch-review-guard:branch-review-guard`）。将命令重命名为 `commands/review.md`，规范调用即 **`/branch-review-guard:review`**（参考成熟插件 `<plugin>:<verb>` 惯例）。README/SKILL.md/AGENTS.md 全部统一为该写法，并说明非插件形态（Cursor/安装器）用 `/branch-review-guard` 或自然语言触发。
- 三个 `skills/*/SKILL.md` 与 `plugin.json`/`manifest.json` 版本同步至 `0.2.6`。

## [0.2.5] - 2026-06-29

### Changed

- **README 瘦身为"介绍 + 教程"**：从 228 行精简到约 120 行，移除版本钉住、刷新≠激活、三路径深度对比、迁移大表等**机制/选型 rationale**；这些迭代思路统一沉到维护方设计文档 `BRANCH_REVIEW_GUARD_PLUGIN_DESIGN.md` §5.4 与本 CHANGELOG，README 内引用 CHANGELOG。安装/使用/更新/卸载/迁移均保留可直接照做的简明步骤。
- **报告落地路径插件感知化**：原硬编码 `tools/<name>/reports/` 在插件形态下不存在；改为"优先 `tools/<name>/reports/`（安装器路径），否则项目根 `branch-review-reports/`（不存在即创建）"。涉及 `branch-review-guard`/`api-change-guard` 的 `SKILL.md`、各 `README`、示例报告。

### Fixed

- 三个 `skills/*/SKILL.md` 的 `version:` 由 `0.2.0` 同步到 `0.2.5`（此前与套件版本脱节，影响安装器版本感知覆盖判断）。
- `branch-review-guard/SKILL.md` 删除插件前的旧维护语（"正本 tools/… 镜像到 .cursor/.claude，改完同步两个镜像"），改为描述插件/安装器/裸读三形态共享同一 `skills/`+`rules/` 内核。
- `AGENTS.md` 插件行补充 VSCode 扩展走 `/plugins` UI（此前只给 CLI `/plugin` 命令）。

## [0.2.4] - 2026-06-29

### Fixed

- **更正 auto-update 开启方式（之前文档写错）**：经核实本机 `claude.exe` 2.1.195 源码字符串（`"Synced autoUpdate= from settings for marketplace"`），auto-update **从 settings.json 读取**，**当前 VSCode 扩展 UI 并无 "Enable auto-update" 开关**，`/plugin` CLI 命令在 VSCode 扩展里也不可用。故 README/设计文档原先"`/plugins` → Enable auto-update"的说法错误，已改为：在 `.claude/settings.json`（项目级随分支共享）或 `~/.claude/settings.json`（用户级仅本机）的 `extraKnownMarketplaces.<name>` 加 `"autoUpdate": true`，存盘后 Reload Window。
- 确认真实可用命令（CLI）：`/plugin install|uninstall|enable|disable|update`、`/plugin marketplace update`。

## [0.2.3] - 2026-06-29

### Changed

- **更新模型改为 auto-update 主导，手动更新降为兜底**：实践中发现"刷新 marketplace ≠ 激活已安装插件"（刷新只 `git pull` 进缓存，激活指针 `installed_plugins.json` 不切换），且当前 UI 不显示版本号，易出现"已取到未激活"。故确立 **auto-update 为标准更新方式**：消费方开 `autoUpdate`（UI 或 `.claude/settings.json` 的 `extraKnownMarketplaces.<name>: {"autoUpdate": true}`），启动即自动 pull+激活；手动"刷新+重装"仅兜底。
- README「更新与卸载」重写：auto-update 升为推荐主路径并给 settings.json 片段、手动更新降级、新增「刷新后没更新」故障排查；安装方式①加"装好后建议立即开启 auto-update"。
- 设计文档 §5.2 同步新增"更新模型：auto-update 取代手动更新"约定。

## [0.2.2] - 2026-06-29

### Changed

- **版本 bump 以触发插件下发**：因 `plugin.json` 设了 `version`，插件被钉死在该版本字符串——`0.2.1` 上后续 push 的 commit 不会下发给已安装用户。本版将 `plugin.json` / `manifest.json` bump 到 `0.2.2`，把以下自 `0.2.1` 起的改动真正交付：复用依赖 skill 的插件形态感知修复、"升级与迁移（场景二）"文档、安装三路径对照与重构。

### Added

- **README 新增「更新与卸载」章节**：明确日常更新无需删项目文件（VSCode `/plugins` 刷新+Install / CLI `marketplace update`+重装）；**版本钉住规则**（维护者每次发布须 bump `version`，否则消费方拿不到更新；或删 `version` 用 commit SHA 自动下发）；自动更新选项；禁用/卸载命令（CLI + VSCode）与"干净卸载、无项目残留"说明。

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
