---
name: branch-review-guard
version: 0.4.0
description: 提测/上线前对整条功能分支（相对主分支的累计变更）做多维度综合代码评审的编排器。统一调度"正确性/Bug、设计/可维护性、安全、测试、可观测/运维、i18n"等自包含 reviewer，并复用 api-change-guard（API/兼容/影响/回归）与 endpoint-perf-review（性能）作为其中两个维度，强制大 diff 分批全覆盖，按可插拔 rules/ 规则包注入技术栈特有深度，产出单份中文可发布性评审报告。当需要在合并前对一条功能分支做一次性、全面的 code review 时使用。
---

# Branch Review Guard

本 skill 是一个**评审编排器（orchestrator）**。它不是再造一个"大而全的单体评审脚本"，而是把一次"提测前整分支评审"拆成多个**专项 reviewer**，分批、按风险聚焦地跑完，再汇总成**一份**中文报告，给出可发布性结论。

设计原则（综合 Google eng-practices、SmartBear/Cisco 实证、Meta/微软/亚马逊实践）：

- **设计 > 正确性 > 复杂度 > 测试 > 命名/注释 > 风格**：高价值维度优先，风格交给自动化。
- **大改动不可线性硬读**：>400 行后人/AI 的缺陷检出率断崖下跌；必须分批 + 按风险聚焦 + 显式声明覆盖范围。
- **复用而非重造**：API/兼容/影响走 `api-change-guard`，性能走 `endpoint-perf-review`，本 skill 只补缺失维度并做汇总。
- **栈无关核心 + 可插拔规则**：核心 checklist 不绑定任何框架；技术栈/项目特有的"坑"与"降噪校准"外置到 `rules/` 规则包，运行时加载叠加。
- **诚实边界**：区分事实/推测/待人工确认；运行时维度（性能 p99、并发竞态、迁移在存量数据下表现）只输出"需运行时验证项"，**禁止下"已验证通过"结论**。

## 可移植性（自包含，不依赖任何特定 Agent）

本 skill 是纯"Agent 规则 + Git 命令"，**不依赖任何 IDE 自带的 `/review` 类命令**，可在 Cursor / Claude Code / Codex CLI / 其他能读文件 + 执行 Git 的 Agent 中运行。

- **支持子代理的 Agent**（如 Cursor 的 explore/Task）：每批 / 每维度**并行派一个子代理**，上下文隔离、互不挤占。
- **不支持子代理的 Agent**：顺序多轮，一批做完再做下一批；用同一套 prompt 与 checklist，结果一致，只是更慢。

本套件的发布载体是 Claude Code 插件（`.claude-plugin/`）；非 Claude Code 的 Agent 经安装器（`install/SKILL.md`）落地到 `tools/<name>/` 或直接读 `skills/<name>/SKILL.md`。各形态共享同一份 `skills/` + `rules/` 内核。

## 规则机制（栈无关核心 + 可插拔规则包）

本 skill 的**核心是栈无关的**：所有维度 reviewer 跑的都是通用 checklist（正确性/设计/安全/测试/可观测的一般要点），不绑定任何具体框架。技术栈/项目特有的"坑"与"降噪校准"全部外置到可插拔的 **`rules/` 规则包**，运行时加载、叠加应用。

- **规则包位置**：随 skill 安装在 `rules/`（canonical：`tools/branch-review-guard/rules/`）；启用哪些包由 `rules/config.yaml` 控制。完整 schema 与消费方式见 `rules/README.md`。
- **baseline 包默认开启**（栈无关的通用规则 + 通用降噪校准）；**栈包可选**（如 `rules/skg-spring/`，默认关闭；同栈团队启用后即可获得机制级深度）。团队也可新增 `rules/<your-stack>/` 自定义包。
- **`discover-new/` 是团队沉淀区**（默认关闭）：`distill`/`rule` 反哺闭环产出、人工确认后的规则落在这里，与上游作者预置的 `skg-spring/` **解耦**——升级插件时两者互不覆盖，也便于区分"作者预置 vs 我们实测沉淀"。要生效在 `config.yaml` 手动开。
- **自动识别启用**：`enabled: false` 的栈包若配置了 `auto_enable.project_markers`，加载时按标记探测目标项目（仓库/模块目录名、`pom.xml` 等构建文件的 groupId/artifactId 的确定性字符串匹配），命中则**本次运行自动启用**——不修改 `config.yaml`，报告"已启用规则包"注明"（自动识别启用）"。显式 `enabled: true` 优先；未命中不启用，不做模糊推断。
- **缺包降级**：未启用某栈包时，对应的机制级深度**自然缺席**——这是预期行为；**通用 checklist 照常全跑**，绝不因"没装某包"而报错或中止。
- **reviewer 如何消费规则**（详见 `rules/README.md`）：每个维度 reviewer 在跑通用 checklist 的同时，按 `dimension` + `applies_to`（语言/框架/路径）匹配出本维度已启用规则；对 `type: finding` 规则按"识别要点 + 取证方式"产出发现，对 `type: calibration` 规则按"校准动作"做降噪（直接越过 / 降级）。
- **严重度以规则为准**：最终定级以"规则 `severity` + calibration 动作"为准，可在规则文件或 `rules/config.yaml` 的 `severity_overrides` 覆盖。

## 调用方式

任意能读本文件的 Agent 都可按下面流程执行。建议提示语：

- `读取 tools/branch-review-guard/SKILL.md，对当前分支相对主分支做提测前综合评审`

命令（**Claude Code 插件形态**为命名空间命令 `/branch-review-guard:review`；其它形态如 Cursor/安装器为 `/branch-review-guard`，或直接用自然语言触发本 skill。下列以模式与选项为准）：

- `/branch-review-guard:review` —— 默认 = `branch`，分支相对 base 的累计变更全维度评审（合并前评审，最常用）
- `/branch-review-guard branch [--base <分支>] [--dimensions <维度逗号分隔>]`
- `/branch-review-guard module <模块名>` —— 只深审某个模块（缩小范围、提高深度）
- `/branch-review-guard diff` —— 仅未提交变更（插件形态另有独立命令入口 `/branch-review-guard:diff`，等价 `review diff`）
- `/branch-review-guard recent <N>` —— 最近 N 个提交

`--dimensions` 取值：`bug,design,quality,security,test,api,perf,observability,i18n`（缺省 = 全部）。

`--thorough`（可选，非默认）：首轮评审后对高风险批次（对外契约/事务并发/鉴权/公共代码）追加"新鲜眼"二轮扫描，连续一轮无新发现即停（见 `## 大 Diff 分批，强制全覆盖`）。

配套命令：
- **`/branch-review-guard:distill [N]`**：从目标项目本地最近 N 份评审报告聚类重复发现，生成 `rules/` 候选规则草稿（见 `## 反馈闭环（distill）`）。
- **`/branch-review-guard:rule <描述> [--type finding|calibration]`**：把一条已确信的经验**手动**快捷生成一条规则草稿（绕过 distill 的 ≥2 次阈值、由人担保泛化），流程见 `prompts/add-rule.md`。

## 工作流程

> **自主一气呵成，中途不停**：被触发后，**自动连贯执行下面 1→12 全部步骤、直接产出完整报告**，不要在任何中间步骤停下来向用户提问或征求"是否继续/是否开始评审"。唯一允许中止并回问用户的情形：(a) base 分支无法确定（且未给 `--base`）、(b) 命令模式/参数歧义无法解析、(c) 目标范围内**无任何变更**。除此之外——**包括 diff 很大（数百文件、上万行）**——都按 `## 大 Diff 分批，强制全覆盖` 自动跑完，绝不因体量或"先确认一下"而暂停。下列步骤（含"建立上下文"）都是你**自己执行**的内部动作，不是与用户的交互节点。

1. **确定范围**：解析命令（默认 `branch`）。按 `## 分析模式` 收集 Git 证据；同时取报告元数据 `git rev-parse --short HEAD` 和时间戳。
2. **建立上下文（自己读，读完立即继续）**：自行读分支目标 / 需求 / 设计文档（仓库根目录与各模块 `docs/` 下的 `*_DESIGN.md`、`*_CONTRACT.md` 等）、`git log` 的 commit message，在报告里用一段话总结"这条分支在做什么、为什么"。**这是评审的前置自查，不是向用户提问的节点**——读完直接进入下一步，**不要停下来等用户**。（无上下文就裸评是反模式，但"无上下文"靠你自己去读文档解决，而非回问用户。）
3. **自动化先行（L1，见 `## 自动化分级`）**：按项目工具链先尝试编译/构建、lint、测试、依赖漏洞扫描（SCA），把风格与明显问题清掉，让人与 AI 只聚焦逻辑、设计、契约。命令不可用时跳过并在报告"评审范围与方法"中说明。
4. **加载规则包（见 `## 规则机制`）**：读取 `rules/config.yaml`，确定本次启用的规则包（`enabled: true` 的包 + `auto_enable` 标记命中目标项目而运行时启用的栈包），供各维度 reviewer 按维度匹配应用。
5. **估规模并分批（见 `## 大 Diff 分批，强制全覆盖`）**：`git diff --stat <base>...HEAD` 拿到变更文件总数与全量清单，按模块/业务域切批。
6. **分维度评审**：对每批应用 `prompts/` 下对应维度的 reviewer prompt（见 `## 评审维度与复用映射`），每个 reviewer 同时注入已启用 `rules/` 规则。支持子代理则并行，否则顺序。
7. **复用专项 skill（弹性路径解析）**：API/兼容/影响/回归调用 `api-change-guard`；对识别出的高风险接口调用 `endpoint-perf-review`（解析与降级规则见 `## 评审维度与复用映射`）。
8. **对抗性验证（降误报，见 `## 对抗性验证与完整性核查`）**：按 `prompts/verify-findings.md` 对所有 P0/P1 发现做 3 视角怀疑者投票（证据核实 / 规则校准 / 触发路径），反驳 ≥2 票否决、恰 1 票降级保留标争议、0 票维持标"已对抗验证"。P2/Nit 不验。
9. **汇总去重**：按 `prompts/consolidate-report.md` 合并各批/各维度发现 + 对抗验证结果，跨批去重、统一优先级（`P0 阻塞 / P1 必改 / P2 建议 / Nit 可选`），成报告草稿。
10. **完整性核查（防漏，见 `## 对抗性验证与完整性核查`）**：按 `prompts/completeness-critic.md` 对账覆盖率、核查维度完整性与可疑批次；小缺口补审（新 P0/P1 同样过第 8 步），补不动的如实修正覆盖声明；结论写入报告第 13 章。
11. **产出报告**：按 `templates/report-template.md` 在项目内生成单份中文报告——优先 `tools/branch-review-guard/reports/`（安装器路径已建则用之），否则在项目根的 `branch-review-reports/`（不存在即创建，建议加入 `.gitignore`）；命名 `branch-review-guard-<mode>-<shortSha>-<timestamp>.md`。
12. **回复**：先给报告链接，再粘贴完整报告正文，正文后固定附 todo 提炼提示（见 `## 回复约定`）。

## 分析模式

某些 Shell（如 Windows PowerShell）不支持 `&&` 连接，命令需逐行执行。一律先 `git fetch origin`，对比 `origin/<base>`（不用可能过期的本地分支）。

### base 分支探测（branch / recent 模式）

1. 若 `origin/master` 存在，用 `master`；
2. 否则 `origin/main`；
3. 否则 `git symbolic-ref --short refs/remotes/origin/HEAD` 探测；
4. 仍不确定则让用户用 `--base` 指定。

### `branch` 模式（默认）—— 分支相对 base 的累计变更

`git diff` 用三点 `...`（自 merge-base 以来本分支引入的改动），`git log` 用两点 `..`：

```bash
git fetch origin
git diff --stat origin/master...HEAD              # 估规模：变更文件总数与全量清单
git diff origin/master...HEAD                     # 全量 diff（可按项目源码后缀过滤，如 -- '*.java' '*.ts' '*.go'）
git diff --name-only origin/master...HEAD         # 文件清单（用于分批与覆盖率核对）
git log origin/master..HEAD --oneline --no-merges # commit 列表（建立上下文）
```

### `diff` 模式 —— 未提交变更

```bash
git diff                  # 工作区未暂存
git diff --cached         # 已暂存
git diff --name-only
```

### `recent <N>` 模式 —— 最近 N 个提交

```bash
git diff HEAD~<N>...HEAD
git log HEAD~<N>..HEAD --oneline
```

### `module <模块名>` 模式

先按 `branch` 取全量清单，再用 `--name-only` 过滤该模块路径前缀（如 `modules/<service-name>/`），对过滤后的文件全量深审。

> 评审范围**排除测试源码**：按语言惯例忽略测试文件（如 `src/test/**`、`*Test.java`、`*_test.go`、`*.spec.ts`、`__tests__/**`）和仅测试的 diff（测试本身在"测试评估"维度单独看）。

## 大 Diff 分批，强制全覆盖

分支累计 diff 通常很大（数百文件、上万行）。**绝不允许因"文件太多"就只分析一部分、把其余直接列入未覆盖。**

1. **估规模**：`git diff --stat <base>...HEAD` 拿到变更文件总数与完整列表。
2. **分批**：切成多批，每批 ≤ ~20-30 文件。分批优先级：
   - 优先**按模块/业务域**（同域入口/数据契约/持久化/业务逻辑一批，利于跨文件推理）；
   - 或**按 commit**（`git log <base>..HEAD --oneline`，每批一个或几个 commit）。
3. **按风险/类型聚焦深读**（不是均匀用力）：
   - **高风险全量深读**：对外契约（HTTP API / RPC / 消息队列 / 对接协议）、事务与原子性、并发与锁、鉴权/越权、删除/类型/枚举/必填字段变更、共享/公共代码改动、配置与 DB 迁移（迁移脚本）。**栈特有的高风险模式**（如特定事务/锁注解、框架装配登记）由启用的 `rules/` 规则包补充识别。
   - **低风险抽样**：getter/样板/纯文案/格式 —— 抽样 + 依赖自动化（生成代码/锁文件等按 baseline 校准抽样处理）。
   - **文件优先级**：入口/接口层 → 数据契约（DTO/VO/Request/Response）→ 跨服务调用（RPC/Client）→ 持久化/转换/业务逻辑 → 其他。
4. **并行/顺序**：支持子代理时每批并行一个子代理；不支持则顺序多轮。
5. **覆盖声明**：报告 `## 分析覆盖范围` 必须写明变更文件总数、批次数、每批覆盖文件数，覆盖率逼近 100%。`## 未覆盖风险` **只**用于真正无法解析的复杂类型/跨仓库调用方，**不得**用来装"因体量没读的文件"。
6. **`--thorough` 二轮扫描（可选，非默认）**：首轮完成后，仅对高风险批次（对外契约/事务并发/鉴权/公共代码）再派一轮"新鲜眼"扫描——同一套维度 prompt、不带首轮结论；连续一轮无新发现即停。**去重对照"所有见过的发现"（含被对抗验证否决的），不是"已确认的"**——否则被否发现每轮复活、永不收敛。

## 对抗性验证与完整性核查（质量编排层）

分批全覆盖解决"每个文件都读过"（广度），本层解决另两类失败：**看似合理但错**（误报）与**读过但没看出来 / 评审自身漏项**（漏报）。

- **对抗性验证**（`prompts/verify-findings.md`，插件形态派 `bru-skeptic` 子代理）：每条 P0/P1 派 3 个**不同视角**的怀疑者——①证据核实（file:line 真实且语义如所述？）②规则校准（是否本应被 calibration 豁免/降级？）③触发路径（影响在真实调用路径上成立？severity 高估？）。**有效反驳必须给 file:line 级反证或规则 id**，"感觉不严重"按维持计。聚合：反驳 ≥2 票否决（移入报告第 14 章附录留证，供 distill 沉淀校准规则）、恰 1 票降级一档保留标 `⚠有争议`、0 票维持标 `✓已对抗验证`。阻塞清单只收经验证的发现，基本免人工甄别。P2/Nit 不验（不阻塞发布，成本不划算）。
- **完整性核查**（`prompts/completeness-critic.md`，插件形态派 `bru-critic` 子代理）：报告定稿前独立核查"这次评审本身"——覆盖率对账（声明 vs 批次回执并集）、维度完整性（有无静默跳过）、可疑的零（高风险批次零发现不默认干净）、待确认遗漏、诚实边界表述。小缺口补审、补不动的如实修正声明，结论写入第 13 章。
- **非子代理环境**：两者都退化为编排器按同一 prompt 顺序自查，结果一致只是更慢。

## 评审维度与复用映射

每条发现统一格式：`[P0/P1/P2/Nit] <维度> — 问题 — 证据(file:line) — 影响 — 建议`。

### 自包含 reviewer（本 skill 的 prompts/，通用 checklist + 注入 rules/ 规则）

每个 reviewer = **栈无关通用 checklist** + **加载本维度已启用 `rules/` 规则**（finding 出发现、calibration 降噪）。

- **正确性 / Bug** —— `prompts/review-correctness.md`：空指针、边界、并发竞态、幂等、错误处理、事务/原子性边界。
- **设计 / 可维护性 / 可扩展性 + 可读性 / 代码质量** —— `prompts/review-design.md`：分层越界、耦合方向、过度设计(YAGNI)、散弹式修改、常量内聚、命名/复杂度/重复/注释一致性。
- **安全** —— `prompts/review-security.md`：鉴权/越权、注入（SQL/命令/模板/反序列化）、敏感信息/PII 泄露、输入校验、依赖 CVE。
- **测试** —— `prompts/review-tests.md`：核心逻辑/异常/边界/兼容场景覆盖、断言质量、可测性、高风险逻辑是否有针对性用例。
- **可观测 / 运维就绪 + 国际化** —— `prompts/review-observability.md`：日志（带上下文、级别、不泄敏）、指标/追踪、超时/重试/降级/熔断、回滚预案、上线依赖（新表/topic/缓存 key）、用户可见文案走 i18n。

### 复用已有 skill（弹性路径解析，不重造）

复用前先**弹性解析**依赖 skill 的位置：

0. **作为 Claude Code 插件运行时（优先）**：`api-change-guard` / `endpoint-perf-review` 随本插件一同加载，**直接以 skill 形式调用**（命名空间 `branch-review-guard:<name>`），**无需按文件路径查找**，也不要因 `tools/`/`.cursor/`/`.claude/` 路径不存在就判"未安装"。

非插件形态再按以下顺序查找**首个存在**的 `SKILL.md`：

1. `tools/<name>/SKILL.md`（canonical 正本）
2. `.cursor/skills/<name>/SKILL.md`（Cursor 镜像）
3. `.claude/skills/<name>/SKILL.md`（Claude 镜像）

以上任一形态命中则读取并应用；**插件未含该 skill 且三处路径全部找不到**才将该维度**降级跳过**，并在报告对应章节显式声明"依赖 `<name>` 未安装、该维度未覆盖（建议安装后补审）"，**不要伪造结论**。

- **API / 兼容性 / 影响范围 / 回归** —— 解析并应用 `api-change-guard` 的 `branch` 模式：请求/返回/枚举/校验/数据兼容性、受影响已上线功能、必须/建议/可不回归。把它的结论折叠进本报告第 5 章，不重复实现；未安装则第 5 章声明未覆盖。
- **性能 / 可靠性** —— **仅对高风险接口**（被本次改动触达的入口接口、重聚合服务）解析并应用 `endpoint-perf-review`：单次请求远程/DB/缓存调用清单、冷缓存最坏、N+1、缓存、降级、超时、索引。结果折叠进本报告第 6 章。**不要对全分支每个方法都跑性能复盘**，只挑高风险入口；未安装则第 6 章声明未覆盖。

## 自动化分级（护栏：禁止越权下结论）

- **L1 可自动定论**：风格/格式/命名、明显空指针/资源未关闭、API/兼容结构化 diff、依赖 CVE、密钥硬编码、SQL 拼接注入模式、测试是否存在/覆盖率数字、i18n 缺失 key。→ 直接给结论。
- **L2 AI 半自动**：设计/架构合理性、复杂度/重复、事务/缓存/锁/越权等**模式化坑**、N+1/调用链放大。→ 给"证据(file:line)+优先级"发现，并标"**待人工确认**"。
- **L3 必须运行时证据**：真实性能（QPS/RT/p99、火焰图、执行计划/`EXPLAIN`、压测）、并发竞态、降级/熔断真实行为、迁移在存量数据下表现与回滚可行性。→ **只输出"需运行时验证项"，严禁给出"已验证通过"。**

## 校准规则（降噪，由 rules/ 提供）

误报校准**不再内联在本文件**，而是由 `rules/` 中 `type: calibration` 的规则提供（baseline 通用降噪默认开；技术栈/团队惯例类校准放在对应栈包，如 `rules/skg-spring/`）。

- reviewer 与汇总阶段按命中的 calibration 规则的"校准动作"处理：**直接越过 / 降级**，是否计入 P0/P1、是否进"待人工确认"均以规则为准。
- 校准只为**降噪**，**不放松**对真实缺陷与对外/C 端接口越权的判定。
- 想增删/调一条校准：编辑 `rules/<pack>/` 下对应规则的 `enabled` / `severity`，或在 `rules/config.yaml` 覆盖——无需改本文件或 prompt 主体。

## 报告结构

见 `templates/report-template.md`。骨架：

```markdown
# <功能分支> 提测前综合代码评审报告
## 0. 结论先行（可发布性: 阻塞/有条件通过/通过 + Top 风险 ≤5 + 总体评价）
## 1. 评审范围与方法（base、diff 口径、文件数、分批与覆盖率、已跑自动化、已启用规则包、已排除测试）
## 2. 变更概览（按模块/功能分组：做了什么、为什么）
## 3. 分维度发现（3.1 正确性/Bug · 3.2 设计与质量 · 3.3 安全 · 3.4 测试）
## 4. 高风险专题（由启用的规则包决定，如事务/并发/对外契约/数据迁移）
## 5. API 与兼容性 / 影响与回归范围（对接 api-change-guard）
## 6. 性能与可靠性（对接 endpoint-perf-review；含"需运行时验证项"）
## 7. 测试评估
## 8. 可观测性与运维就绪
## 9. 国际化（如适用）
## 10. 阻塞项清单（Merge 前 must-fix，P0/P1 汇总；只收经对抗验证项）
## 11. 非阻塞改进 / Nit（含教学性建议）
## 12. 待人工确认项
## 13. 分析覆盖范围与未覆盖风险（含完整性核查结论）
## 14. 附录：对抗验证记录（被否决/降级的发现与反证）
```

## 回复约定

最终回复必须**同时**包含报告链接和报告正文，不要只返回链接。所有面向用户的输出用中文（代码标识符、命令、文件路径、类名、方法名、注解、源码引用保留原文）。固定顺序：

```markdown
报告文件：[<filename>](<relative-path>)

# <功能分支> 提测前综合代码评审报告

...完整报告正文...

---
是否需要我将可以直接代码落地修复的项提炼成 todo 清单（剔除纯运行时验证、发版编排、人工确认类）？按「必要性 × 成本」分三档，每项说明：问题 → 不改的后果 → 为什么值得改。
```

报告很长时也不能只给总结，必须保留 `## 报告结构` 的核心章节；必要时只压缩较长代码块。正文后的 **todo 提炼提示为固定文案**，每次评审回复末尾都要附上（用户确认后再生成清单，不要未经确认就直接展开）。

## 可靠性规则

- Git diff 与文件内容是事实依据；区分**事实 / 推测 / 待人工确认**。
- 不编造调用方；影响范围给依据与概率。
- 每条发现可定位（`file:line`）+ 可执行建议；区分阻塞与 Nit。
- 显式声明覆盖率与未覆盖，**绝不把没读的当已评审**。
- 同时肯定"做得好的地方"（Google: Good things），基调是"持续改进而非追求完美"。
- 注释掉的接口/路由代码不视为真实接口。
- 运行时维度只给"需运行时验证项"，不下"已通过"。

## 反馈闭环（distill + 手动 rule）

评审的历史产出可反哺规则包与开发侧，两条入口共享同一套落地关卡（草稿落报告目录旁 `rule-drafts/`、`enabled: false`、**人工确认后**提交插件仓库 `rules/<pack>/` 才生效，**绝不自动写规则包**）：

- **`/branch-review-guard:distill [N]`**（数据驱动，流程见 `prompts/distill-rules.md`）：读**目标项目本地**最近 N 份报告聚类重复发现。**先把每条发现归到"代码实例"（同 file + 同根因，不死磕 file:line）再计数，同一实例跨报告只计 1 次**——漏报模式（同维度同根因跨 **≥2 个不同实例**）→ 候选 `finding`；对抗验证附录中反复被否决的模式 → 候选 `calibration`。
  - **遗留项分诊**：同一实例在 ≥2 份报告中反复报出、位置基本未变的，**不是漏报**（评审每次都报了、是开发一直没改），从 finding 剔除、单列为「反复报出但未修复的遗留项」，给两个出口——认可是真问题只是没排期 → known-issue 不生成规则；判定不成立/不重要 → 转 `calibration` 让评审器以后豁免。**避免把"一直没改的老问题"误固化成 finding**。
- **`/branch-review-guard:rule <描述> [--type ...]`**（人担保，流程见 `prompts/add-rule.md`）：把一条已确信的经验**手动**快捷生成规则草稿，**绕过 distill 的 ≥2 次阈值**（泛化由录入人负责）。典型用途：把 distill 遗留项一句话转 calibration，或一眼确信要规则化的强 case。

开发侧 skill / CLAUDE.md 引用同一套 `rules/` 的"修法"节，即可把评审教训前置为写码禁区。

## 误判记录

工具输出不准确时，按以下格式记录，便于迭代 SKILL / prompt / 规则：

```markdown
### Case: <短标题>
- Input: 分支 / 模块 / diff 摘要
- Wrong output: 工具输出了什么错误结论
- Expected output: 评审期望的正确结论
- Fix rule: 需要更新的 SKILL 规则、prompt 规则、护栏，或 rules/ 规则条目
```
