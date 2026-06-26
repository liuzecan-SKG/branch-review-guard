# Changelog

本文件记录 API Change Guard 的版本变更，版本遵循语义化版本（SemVer）。

> 说明：自 `0.2.0` 起，版本号与 branch-review-guard 套件统一（见套件 `manifest.json`）；以下 `1.x` 为本工具并入套件、完成栈泛化之前的历史版本，按原样保留以记录演进。

## [0.2.0] - 2026-06-26

### 变更
- **栈泛化**：核心逻辑从「Java/Spring 专用」泛化为「静态类型后端通用」。文件分类、契约信号门槛（API 关键词）、报告结构改为栈无关概念（控制器/路由、请求/返回契约、RPC/IDL、消息契约），默认示例仍保留 Java/Spring。
- **规则外置（可插拔）**：技术栈 / 项目特有的契约深度检查从 skill 正文移到可插拔规则机制（`rules/`，见 `rules/README.md`）。skill 在工作流程中新增「加载规则包」步骤，运行时加载并叠加应用 `dimension: api` 的已启用规则；缺包时降级为通用契约分析（不报错），并在「分析覆盖范围」注明。
- `description` 去 SKG 化；frontmatter 新增 `version: 0.2.0`。
- 文件优先级、各类型读取上限、`> 30` 文件分批扫描、`mine` 口径限制说明、base 分支探测、回复约定等核心规则保持不变，仅措辞栈无关化。
- 「分析覆盖范围」新增「规则包状态」一项（启用了哪些 `dimension: api` 规则包；未启用栈特有包时注明栈专有协议未做机制级深度检查）。

### 移除（迁移到 `rules/skg-spring/`）
- SKG Health Global 专有内容不再写死在本 skill：统一返回 `CommonResult<T>`、采集契约 `DataCollectDto<T>`、手表/4G/蓝牙上报 `@Watch4gDataLength`、Sa-Token 鉴权、Dubbo/Feign `Remote*` 命名、公司后端规范细节等，迁移至默认关闭的 `rules/skg-spring/` 规则包（由同栈团队启用）。
- 原「公司后端规范检查」一节拆分为栈无关的「通用契约检查」+「规则包集成」两节。

### 文档
- 新增 `## 规则包集成` 说明如何接入 `rules/` 机制（加载 → 应用 → 缺包降级）。
- 示例报告改为栈无关示意（顶部标注「示意，非真实结论」），去除 SKG 业务细节。
- `generate-mockmvc` / `generate-test-cases` prompt 去除项目专有断言/鉴权细节，改为「项目特定鉴权 / Mock / 错误码由规则包或开发补充」，保留通用骨架生成思路。

## [1.2.0] - 2026-06-24

### 新增
- 大 diff 分批扫描：`branch` / `recent` 模式在变更文件超过深度分析上限时，强制按模块/包或按 commit 分批、逐批分析后汇总成一份报告，覆盖率逼近 100%（支持子代理的 Agent 可每批并行）。

### 变更
- `> 30` 文件不再「只分析接口相关、其余列入未覆盖」，改为进入分批扫描模式，必须全覆盖。
- `## 未覆盖风险` 只用于真正无法解析的内容，不得用来装「因体量没读的文件」。

### 文档
- SKILL.md 正文与 description 全面中文化（仅语言，规则与含义不变）。

## [1.1.0] - 2026-06-23

### 新增
- 新增 4 种分析范围模式，每种独立命令，`analyze diff` 仍为默认：
  - `analyze diff`：未提交变更（默认）
  - `analyze branch`：功能分支相对主分支的累计变更，用于合并前评估
  - `analyze recent <N>`：最近 N 个提交
  - `analyze mine`：仅本人在本分支的提交（commit 口径）
- base 分支探测：优先 `master`，兜底 `main`，再用 `git symbolic-ref` 探测或由用户指定。
- branch / recent / mine 模式强制先 `git fetch origin`，并一律对比 `origin/<base>`，避免本地分支过期。
- 大 Diff 规则新增「分支 / 最近模式分批」：先 `git diff --stat` 估规模，超限按 commit 或模块分批分析。

### 变更
- 报告「分析覆盖范围」需注明分析模式、base 分支、commit 范围、实际使用的 diff 命令。
- 报告文件命名调整为 `api-change-guard-<mode>-<shortSha>-<timestamp>.md`。

### 说明
- `analyze mine` 是 commit 口径过滤，不是「本人净改动 diff」；多人改同一文件或同一行无法精确切分，影响分析与回归判断仍以 `branch` 模式为权威基准。

## [1.0.0] - 2026-06-05

### 新增
- 基于 Git diff 的后端接口变更影响分析，纯 Cursor Skill + Git 命令方案，不依赖 Python。
- 影响范围优先的固定报告结构、大 Diff 分流规则、测试源码排除、中文输出约束、多 Agent 通用化。
