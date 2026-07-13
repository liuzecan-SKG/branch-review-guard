# Changelog

本文件记录 Branch Review Guard 的演进。

## [0.6.0] - 2026-07-13

v0.6.0 聚焦**提升评审召回与准确**（防漏报），起因是一次真实对照：同一条分支（skg_health_global，250 文件/216 commit），同事的 114-agent 报告查出了本插件漏报的 R1–R12 一批问题。用「单点证伪 + 必败点压测」的对抗式编排（5 召回方案 × 10 怀疑者 × 裁判 + 批评家，~17 agent）定位漏报根因后，落地四块对症改动。**前置结论**：上一版（v0.5.x）的优化方向是精度/信任轴，对召回轴问题基本无效；本次转向召回轴。DDL/配置类缺失（R2/R3/R4）按团队惯例继续由 calibration 规则豁免、本次不动。

### Added

- **DLP 透明加密环境对策（横切纪律）**（`SKILL.md` 新增 `## DLP 透明加密环境对策` 节 + 工作流程第 1 步引用 + `report-template.md` 第 1 章声明位）：工作区被主机 DLP 透明加密时，按内容检索的工具（grep/rg/Semgrep）读到密文、返回"假零命中"，双向有害（漏报 + 把真发现误杀）。本次把它从"约定"变成"机制"——①开局明文自检（Read 一个源文件判定是否加密，致盲则报告顶部红字警告）；②内容检索去 grep 化（文件名用 Glob、内容用 Read、已提交文件走 `git show`）；③否定型结论必须标注取证方式 `[Read]`/`[git]`/`[Grep·仅非DLP可信]`，DLP 下 grep 取证的否定结论一律退回 Read 重核。
- **业务语义 / 不变式维度**（新增 `prompts/review-business-invariant.md` + 子代理 `agents/bru-business-invariant.md` + 挂进 orchestrate 第 6 步 + SKILL 维度映射 + commands 子代理清单）：专捞"代码特征抓不到、违反的是业务道理"的漏报（R7/R8/R10/R12 型）。靠**主动提问 + 差分对照**发现，不靠模式匹配——先列五类对象清单（业务不变式/功能孪生/哨兵值/删除清理/状态查询接口），再套五个追问模式（哨兵值误判/孪生差分/不变式多路径绕过/孤儿/枚举 oracle）。产出含"正例·待证伪"声明，对接对抗层第 4 视角。`--dimensions` 取值新增 `semantic`。

### Changed

- **对抗层加第 4 视角"假设证伪"捞漏报**（`verify-findings.md` + `bru-skeptic.md` + SKILL 工作流程/对抗节 + orchestrate 第 8 步 + commands/review.md/diff.md，评审侧 5 处冗余同步）：原 3 视角只反驳"已报发现"降误报，从不证伪"正例/零发现"，导致 R9（点赞幂等）被错判成正例放行。新增第 4 视角对"做得好/已复核通过"项与高风险批次"零发现"声明主动找反证；翻案须 file:line 级反证、从严防误翻真·正例，absence 类反证不用 grep（DLP 假零）。聚合独立计票。
- **对抗层与批评家加 DLP 取证核查**（`verify-findings.md` 证据核实视角 + `completeness-critic.md` 新增第 6 条核查 + `bru-skeptic.md` 加 DLP 纪律与输出取证字段）：DLP 下 grep 取证的否定结论判不可信、强制退回 Read。
- **分批去外围降权 + 多样切法 + 防中段衰减**（`SKILL.md ## 大 Diff 分批` 第 2/3 步 + orchestrate 第 5 步）：切法池增加"按调用链切/单文件逐段深读"（修 R6 大文件中段漏读）；明确**降权只针对代码类型（getter/样板/文案/生成代码），不针对外围业务模块**（修 R11 LoseWeight 漏报——外围 controller/service 与主链路一视同仁全覆盖）；每批回传"已深读文件清单 + 逐段行号"防 lost-in-the-middle。
- **`--thorough` 升级为 loop-until-dry 多轮扫描**（`SKILL.md` 选项说明 + 大 Diff 第 6 步 + orchestrate 第 6 步 + commands/review.md/diff.md + README，评审侧多处同步）：原"二轮即停"改为"一轮轮派新鲜眼直到**连续 2 轮零新发现**才停"——挖干为止、轮数不设人为上限，按 diff 复杂度自然收敛（小 diff 常 2-3 轮、大而复杂的可能 5-6 轮），仅留 8 轮安全阀防"每轮换措辞永不收敛"的死循环。借鉴同事 114-agent 的召回来自 pass 累积。诚实边界：同模型相关性盲点不随轮数消失——对注意力型漏报有效、对业务语义型见顶快，想突破靠换模型（异构复审）。
- **P0/P1 交叉确认**（借鉴同事"双人 2/2"；`SKILL.md` 对抗节 + 工作流程第 8 步 + orchestrate 第 8 步 + `verify-findings.md` 新节 + report-template 第 1/10 章）：与怀疑者投票**正交**——投票查"发现对不对"（带着结论找反证），交叉确认查"有几个独立 reviewer 命中"（不带结论从零重看）。每条 P0 与 P1 另派一个独立 reviewer 重看：≥2 独立命中标 `✓✓交叉确认`、仅 1 命中标 `⚠单源`（建议人工复核）；为确认而派的 reviewer 常附带捞回新发现。P0/P1 都做（漏报/误判在 P1 同样常见，如同事 R2–R6 均为 P1），P2/Nit 不做。诚实边界：`model: inherit` 下两 reviewer 同底模，`✓✓` 是弱独立非真异构——强独立要靠换模型多轮或人工复核。
- **禁止"同 SHA 无增益"投机**（新增横切纪律 `SKILL.md ## 每次评审都是独立执行` + 工作流程中止条件 (c) 收紧 + orchestrate 第 0 行 + commands/review.md/diff.md + 异构复审 SOP 防投机提醒）：修一个隐蔽缺口——agent 运行时会自作主张"本次代码与历史报告同一 SHA / diff 字节一致 → 无信息增益 → 不重跑子代理编排，改为只 Read 复核历史结论"。这会**直接废掉** loop-until-dry（同 SHA 多轮）、P0/P1 交叉确认（同处重看）、尤其**异构复审**（换模型后 SHA 不变，被当"无需重跑"则复用旧模型结论、换模型形同虚设）。纪律：同一 SHA / diff 与历史一致是**正当重审场景**，被触发一次就完整跑一次编排，历史报告只当参考上下文、不替代本次真跑；"无变更"中止仅指 **diff 为空**，不指"diff 和上次一样"。
- **计数同步**（CLAUDE.md 冗余纪律）：评审侧子代理 7→8、维度 5→6、总计 10→11 只读子代理；`plugin.json`/`manifest.json`(suite+skill)/`SKILL.md` frontmatter 版本 → 0.6.0；`AGENTS.md`/`README.md`/`CLAUDE.md` 计数同步。

### Notes

- **明确不做**（团队决策）：DDL/配置类 absence 问题（R2/R3/R4）继续由 `calibration-ddl-nacos`/`calibration-release-orchestration` 豁免——无目标库事实源时报"缺 DDL"是误报洪水，校准选择不报是诚实边界体现。Schema Oracle / absence-checker / 配置三角核对等方案本次不引入。
- **需运行时验证项**（落地后需在真实分支上验，暂不能断言已验证）：① DLP 明文自检的判定准确率（`%TSD-Header`/NUL 检测在不同加密产品下是否都成立）；② 第 4 视角"假设证伪"的翻案率与误翻率（会不会把真·正例翻错、制造噪音）；③ 业务语义维度对 R7/R8/R10/R12 这类的实际召回增益（这些是业务语义盲区，预期只能部分缓解、需人机协同——团队可维护"领域不变式台账"喂给该维度提升命中率）；④ 去外围降权后全模块深读是否重新引入中段衰减（需配小批次覆盖回执观察）；⑤ loop-until-dry 的实际收敛轮数与增量召回（"连续 2 轮零新发现"判据下大 diff 实际跑几轮收敛、边际收益何时归零、会不会有 diff 逼近 8 轮安全阀）；⑥ P0/P1 交叉确认的 `⚠单源` 占比与"附带捞回新发现"的真实产出率（弱独立同底模，交叉确认到底能提供多少额外信号需实测；P1 全量交叉确认的实际增益）。
- **借鉴同事 114-agent 的诚实定位**：本次落地的 loop-until-dry 与 P0/P1 交叉确认是"同模型内"的召回/精度改良，天花板是同底模相关性盲点。真正对标"114-agent + 双人 2/2"的强独立，要靠**主会话换模型跑多轮对照**（异构复审）与**人工/同事复核关键 P0/P1**——这两条属使用实践、非插件内代码，SOP 见 `docs/异构复审-SOP.md`、机制见 `SKILL.md ## 使用建议：异构复审（强独立召回）`。

## [0.5.1] - 2026-07-07

v0.5.1 修 design-panel 的需求澄清缺陷：开发者常一轮讲不清需求、细节留不确定点，而现状澄清关卡门槛过高（仅「目标行为本身缺失」才回问），细节不确定被直接塞进假设清单开跑——猜错时用户要等整轮擂台（7 子代理 / ~50–120 万 token / 8–15 分钟）跑完、在报告里才看到假设、再返工。本次把澄清改为三层机制。本优化本身即用 design-panel 的「设计擂台」模式产出（3 设计代理 + 3 怀疑者 + 1 裁判；三方案全被削弱、零推翻，暴露「纯 Markdown 无续跑」是所有方案共撞的硬边界），过程留证见 `branch-review-reports/design-panel-clarify-optimization-*.md`。

### Changed

- **需求澄清改为三层机制**（`skills/design-panel/prompts/clarify-requirement.md` + `SKILL.md ## 需求模糊处理` + 工作流程节）：
  - **L1 开跑前亮假设（主路径，不停）**：新增 **P1.5「假设预检段」**（`prompts/orchestrate-design-panel.md`）——P1 建完事实底座、P2 派 designer 前，把「承重假设 Top-N」（每条含推断依据 file:line + 若错波及哪个方向）打印给用户看一眼，**编排器不 yield、同一回合直接续跑**，用户可 Esc 打断纠偏。等同现状「进度行 + Esc 中止改档」（SKILL.md 成本档位节），只把 payload 从「档位/时长」升级为「档位/时长 + 承重假设」，是同一非阻塞点的信息超集，不比现状更易卡住；让用户第一次能在花掉 50–120 万 token 前看到编排器假设了什么。
  - **L2 逃生阀（罕见才停）**：终止性单次回问的触发从「仅目标行为缺失」收严为**三元合取**——承重 ∧ **P1 勘察后仍不可推断** ∧ 二元翻转推荐。判定时点从 P0 挪到 **P1 之后**：P0 阶段代码未系统勘察，此时判「不可推断」往往是「还没查」，会误触发（P0 信息不全的老坑，v0.5.0 的规模预判 C5 同病）。目标行为本身缺失/自相矛盾仍走 L2 且无需等 P1。
  - **L3 兜底（不停）**：其余细节不确定进「假设清单」事后纠偏，「能推断的绝不问」不变。
  - **设计取舍**：纯 Markdown 无超时续跑——agent 主动发问是「默认死局、静默不安全」，用户主动 Esc 是「默认继续、静默安全」，故 L1（不停、只亮信息）优先，L2 停顿只留给「不问就整轮白跑」的关键岔路口。这是对 v0.2.9「停在等用户输入」教训的正确落点：不回退到「有不确定就停」，也不假装「不回复能续跑」。
- **澄清措辞设计侧四处同步**（CLAUDE.md 冗余纪律）：L2「恰好一次终止性、不承诺续跑」+ 三层机制措辞在 `SKILL.md` / `prompts/orchestrate-design-panel.md` / `commands/design.md` + 权威源 `prompts/clarify-requirement.md` 四处逐字一致（v0.2.9 的 bug 正是几处措辞不一致致停）。
- **版本同步**：`skills/design-panel/SKILL.md` frontmatter + `.claude-plugin/plugin.json` + `manifest.json`（suite + design-panel 条目）→ 0.5.1。评审侧 branch-review-guard 及依赖 skill 本次未改、版本不动。

### Notes

- 本次不动评审侧 branch-review-guard 的自主执行纪律（评审输入是确定的 diff，无此模糊性）。
- **需运行时验证项**（落地后需在真实需求上验，暂不能断言已验证）：① L1「编排器不 yield 直接续跑、Esc 可中止」是否在目标 Agent 运行时真如现状进度行的 Esc 一样工作；② L2 三元合取触发率是否真守在低位（不 FALSE-FIRE）；③ P1.5 假设 Top-N 的「若错波及哪个方向」在方案尚未生成时能标多准。

## [0.5.0] - 2026-07-06

v0.5.0 引入**设计侧姊妹技能 design-panel**：与评审侧 branch-review-guard 形成「设计出方案 / 评审守出口」的双子星。需求方案设计阶段并行派 N 个互不可见的设计代理从不同价值取向独立成案 → 对每案承重论断派怀疑者做 file:line 级对抗质证 → 裁判打分产出对比表 + 推荐方案 + 嫁接综合方案。本技能的设计本身即用「设计擂台」模式产出（3 设计代理 + 3 怀疑者 + 1 裁判），过程留证与质证裁决见 `skills/design-panel/DESIGN.md`。

### Added

- **design-panel 编排器**（`skills/design-panel/SKILL.md` + `prompts/` 5 份 + `templates/`）：P0 定标 → P1 建事实底座 → P2 并行独立成案 → P3 对抗质证 → P4 裁判裁决 → P5 诚实边界核查 → P6 产出报告与精炼设计稿。自主一气呵成，唯一回问例外 = 需求「目标行为」本身缺失（终止性单次，**不承诺「不回复则按默认继续」**——纯 Markdown 无超时续跑通道，避免复刻 0.2.9 同型 bug）。
- **3 个设计侧只读子代理**（`agents/dsp-designer.md` / `dsp-skeptic.md` / `dsp-judge.md`）：单文件参数化视角（沿用 `bru-skeptic` 先例）；frontmatter 严格 `tools: Read, Grep, Glob, Bash`——只读是**机制白名单**而非 prompt 里的一句话（避免 write-enabled 的设计代理顺手改目标项目文件）。
- **`/branch-review-guard:design` 命令**（`commands/design.md`）：调用 design-panel skill，支持 `--input`/`--module`/`--variants`/`--quick`/`--thorough`。
- **质证护栏四件套**（`prompts/challenge-claims.md` + `judge-and-graft.md`）：单挑战者替代评审侧 3 票聚合，配「核查动作记录 / 论断外硬伤出口 / 推翻票裁判抽验 / 战绩不进权重」对冲单挑战者的「假维持」腐蚀横向排名。
- **规模降档（合取护栏 + 一票否决）**（`prompts/clarify-requirement.md`）：预估 ≤5 文件 **且** 无对外契约/存储结构/枚举必填变更 **且** 无跨模块权衡才降为单方案直答；高风险小 diff（契约/迁移/枚举）一票否决降档。
- **设计→评审闭环**：精炼设计稿 `<slug>_DESIGN.md` 提示用户移入 `docs/`，`:review` 的「建立上下文」自动读取（复用既有机制，零改动）。
- **项目本地规则叠加（开发-评审标准一致）**（v0.5.0+）：评审时 best-effort 叠加读取**被评审项目根**的 `branch-review-rules/`（与 `branch-review-reports/` 平行），独立于 `config.yaml` pack 开关、直接全量按 `dimension` + `applies_to` 加载（目录不存在则跳过）；开发侧 skill（如项目本地 `skg-health-global-coding-standards` 的机制 H）读**同一份**——单一源、改一处两边同步生效。涉及 `branch-review-guard/SKILL.md`（规则机制节 + 工作流程第4步）、`orchestrate-branch-review.md`（第3/6步）、5 个 `review-*.md`（筛选步）、`consolidate-report.md`（第1章注明）、`rules/config.yaml` 顶部注释。项目主人自放项目特有规则，通常 `.gitignore` 忽略、纯本地，不随插件分发（装了插件但不在自己项目放 `branch-review-rules/` 的人零影响）。

### Changed

- **distill 取样加前缀过滤**（`commands/distill.md` + `prompts/distill-rules.md`）：只取 `branch-review-guard-*`，排除 `design-panel-*` 与 `*_DESIGN.md`——设计裁决不沉淀为规则，design 与 review 共享 rules 供给是**单向**的（rules → design 消费，design 不产 rules）。
- **降级口径分化**：评审侧「结果一致，只是更慢」；**设计侧「独立性弱化」**（隔离即产品，顺序模式同上下文生成会趋同），两套口径刻意不同、不得混用。
- **rules 侧 v1 只消费不改 schema**：design-panel 把已启用栈包 `type: finding` 规则作设计约束注入 designer/judge，`dimension` 不匹配时按 `summary` 摘要注入；`applies_phase` 字段及评审侧 phase 过滤**推迟 v2**（牵动 `rules/README.md` 消费逻辑、`branch-review-guard/SKILL.md` 规则机制、各 `prompts/review-*.md`、`commands/rule.md`、`prompts/add-rule.md` 等十余处）。
- **计数同步**：子代理 7 → **10**（+3 `dsp-*`）、skill 3 → **4**、命令 4 → **5**（+ `:design`）；`plugin.json`/`marketplace.json` 的 description、`AGENTS.md`、`README.md`、`CLAUDE.md` 一并更新。
- **版本同步**：`skills/design-panel/SKILL.md` + `skills/branch-review-guard/SKILL.md`（后者因新增 `:design` 互链改动）frontmatter + `.claude-plugin/plugin.json` + `manifest.json`（suite + branch-review-guard 条目 + 新增 design-panel 条目 `requires: ["branch-review-guard"]`）→ 0.5.0。

### Notes

- design-panel 依赖 branch-review-guard（共享 `rules/` 与 `reports/` 目录）；`manifest.json` 声明 `requires`，安装器装 design-panel 时连带装 branch-review-guard，reports 目录由后者的 `reports_gitignore` 覆盖、design-panel 条目不重复声明。
- 设计阶段对抗验证强度低于评审侧（设计裁决由人拍板、误杀不阻塞发布），但配四件套护栏防单挑战者方差腐蚀横向排名；诚实边界由编排器 P5 用固定 checklist 独立核查（非新增 critic 子代理，控成本）。

## [0.4.0] - 2026-07-05

v0.4.0 收紧 distill 反馈闭环的**计数语义**，补一条"人担保"的手动加规则入口，并新增 `discover-new` 团队沉淀区把反哺规则与上游预置解耦，堵住"把一直没改的老问题误固化成规则"的漏洞。

### Fixed

- **distill 漏报计数从"发现条数"改为"代码实例数"**（`prompts/distill-rules.md`）：原逻辑"同根因 ≥2 次 → finding 候选"会把**同一处一直没修的遗留问题**（每次评审都被报一次）误算成"反复出现的模式"。现在**先把每条发现归到"代码实例"（同 file + 同根因语义，不死磕会漂移的 file:line），同一实例跨报告只计 1 次**；finding 候选的判据改为**同根因跨 ≥2 个不同实例**——只有跨多处才是"值得规则化预防的模式"。质量约束节新增对应条目。

### Added

- **distill 遗留项分诊**（`prompts/distill-rules.md` 新增第 5 步）：把"同一实例在 ≥2 份报告中反复报出、位置基本未变"的项从 finding 剔除、单列为「反复报出但未修复的遗留项」。语义澄清：这类**不是漏报**（评审每次都报了，是开发一直没改），反复不改常意味"团队认为它没必要/不成立/不重要"。distill 不替用户裁定，给两个出口——① 认可是真问题只是没排期 → known-issue，不生成规则；② 判定不成立/不重要 → 转 `calibration` 让评审器以后豁免（成为 calibration 规则的**第二个来源**，与"对抗验证被否"并列）。第 8 步输出新增遗留项清单。
- **`/branch-review-guard:diff` 独立命令**：新增 `commands/diff.md`，等价 `/branch-review-guard:review diff`（仅未提交变更，迭代期边写边查）。动机：模式参数在 `/` 自动补全菜单里不可发现，用户会误以为没有 diff 能力；独立命令入口让它出现在菜单里。只接受 `--dimensions`/`--thorough` 选项，带其它模式词按参数歧义回问。命令数 3 → 4（review + diff + distill + rule）。
- **手动加规则命令 `/branch-review-guard:rule`**：新增 `commands/rule.md` + `prompts/add-rule.md`。从一句"问题/模式描述"（`--type finding|calibration`、`--pack`、`--dimension`、`--severity`）快捷生成一条规则草稿，走与 distill **完全相同**的落地关卡（`rule-drafts/`、`enabled: false`、人工确认后提交插件仓库才生效）。定位是"**人担保**"入口——**绕过** distill 的 ≥2 次阈值，泛化判断由录入人负责；典型用途：把 distill 的遗留项一句话转 calibration，或一眼确信要规则化的强 case。命令数 2 → 3（review + distill + rule）。
- **`discover-new` 团队沉淀区规则包**：新增 `rules/discover-new/`（默认关），作为 `distill`/`rule` 反哺产出的落点，与上游作者预置的 `skg-spring/` **解耦**——升级插件时两者互不覆盖，便于区分"作者预置 vs 本团队实测沉淀"。`distill`/`rule` 的 `--pack` 默认值由 `skg-spring` 改为 `discover-new`；在 `manifest.json` packs 与 `rules/config.yaml` 注册，`rules/README.md`、`SKILL.md` 规则机制节说明。

### Changed

- `SKILL.md`：`## 反馈闭环（distill）` 更名扩为 `## 反馈闭环（distill + 手动 rule）`，写入实例计数、遗留项分诊、两条入口共享关卡；调用方式节新增 `rule` 命令；version → 0.4.0。
- `commands/distill.md`：聚类说明同步实例计数与遗留项分诊。
- README/AGENTS.md：命令 2 → 4（review + diff + distill + rule）。
- 版本同步：`SKILL.md`/plugin/manifest（suite + skill 条目）→ 0.4.0。

## [0.3.0] - 2026-07-03

v0.3.0 引入**质量编排层**：用结构对抗"看似合理但错"（误报）与"读过但没看出来 / 评审自身漏项"（漏报）。设计 rationale 见维护方设计文档 `BRANCH_REVIEW_GUARD_PLUGIN_DESIGN.md` §11。

### Added

- **对抗性验证（降误报）**：新增子代理 `agents/bru-skeptic.md` + `prompts/verify-findings.md`。每条 P0/P1 在汇总前经 3 个**不同视角**怀疑者投票（①证据核实 ②规则校准 ③触发路径）；有效反驳必须给 file:line 级反证或规则 id，"感觉不严重"按维持计；反驳 ≥2 票否决（移入报告新第 14 章附录留证）、恰 1 票降级一档保留标 `⚠有争议`、0 票维持标 `✓已对抗验证`。阻塞清单只收经验证发现，目标是免人工逐条甄别。P2/Nit 不验（成本控制）。token 成本预期上浮约 30-60%（随 P0/P1 数量），已获使用方确认接受。
- **完整性批评家（防漏）**：新增子代理 `agents/bru-critic.md` + `prompts/completeness-critic.md`。报告定稿前独立核查"评审本身"：覆盖率对账（声明 vs 批次回执并集）、维度完整性（有无静默跳过）、可疑的零（高风险批次零发现不默认干净）、待确认遗漏、诚实边界表述；小缺口补审（新 P0/P1 同样过验证）、补不动的如实修正覆盖声明，结论写入第 13 章。
- **`--thorough` 二轮扫描（可选，非默认）**：首轮后仅对高风险批次（对外契约/事务并发/鉴权/公共代码）追加"新鲜眼"扫描，连续一轮无新发现即停；去重对照"所有见过的发现（含被否决的）"防复活循环。
- **`/branch-review-guard:distill` 反馈闭环**：新增 `commands/distill.md` + `prompts/distill-rules.md`。读取目标项目**本地**报告目录最近 N 份报告，聚类重复发现——漏报模式（≥2 次）→ 候选 `finding` 规则草稿、对抗验证附录中反复被否模式 → 候选 `calibration` 草稿；草稿落本地 `rule-drafts/`（`enabled: false`），**人工确认后**提交回插件仓库 `rules/<pack>/` 才生效，绝不自动写规则包（防单 case 过拟合）。开发侧引用同套 rules/ 的"修法"节即可把评审教训前置为写码禁区。
- **上线协同项全豁免**：新增 `rules/skg-spring/calibration-release-orchestration.md`——新表/MQ topic/消费组/缓存 key 预建、配置各环境就绪、发版编排类提示直接越过不报告（团队有独立上线 checklist 兜底）；分支内真实包含的 `*.sql`/配置 diff 与代码自身装配缺陷不在豁免内。
- **报告末尾固定 todo 提示**：报告正文后固定附"是否需要将可直接代码落地修复的项提炼成 todo 清单（剔除运行时验证/发版编排/人工确认类），按必要性×成本分三档"，用户确认后再生成。
- **规则包自动识别启用（auto_enable）**：`rules/config.yaml` 的栈包可配 `auto_enable.project_markers`；评审加载规则包时按标记做**确定性匹配**（仓库/模块目录名、`pom.xml` 等构建文件 groupId/artifactId），命中则该包本次运行自动启用——不修改 config 文件，报告注明"（自动识别启用）"。`skg-spring` 预置标记 `skg-health-global`/`skg_health_global`，发布默认仍 `enabled: false`，同栈项目零配置获得机制级深度，其它项目不受影响。

### Changed

- `SKILL.md` 工作流程 1→10 扩为 **1→12**（插入第 8 步对抗性验证、第 10 步完整性核查），新增 `## 对抗性验证与完整性核查（质量编排层）` 与 `## 反馈闭环（distill）` 两节；orchestrate / consolidate / review 命令三处同步（含自主执行口径）。
- 报告模板：第 1 章新增验证与核查方法行；第 10 章只收经对抗验证项（带 `✓/⚠` 标注）；第 13 章新增"完整性核查（批评家）"小节；新增**第 14 章附录：对抗验证记录**。
- README/AGENTS.md/plugin.json：子代理数 5 → **7**（5 维度 + 怀疑者 + 批评家），命令 1 → 2（review + distill）。
- 版本同步：`SKILL.md`/plugin/manifest → 0.3.0；修正 manifest.json 中 skills 条目版本与各 `SKILL.md` frontmatter 的历史脱节（api-change-guard、endpoint-perf-review 条目 0.2.0 → 0.2.6）。

## [0.2.9] - 2026-06-29

### Fixed

- **修复评审中途暂停、停在「建立上下文」等用户输入的问题**：原 `SKILL.md`/`orchestrate`/命令把"建立上下文"写成节点且有"无上下文不要开始评审"等措辞，导致 agent 读完上下文后停下来回问用户（尤其大 diff 时）。现在三处统一加**自主执行指令**：被触发后连贯跑完 1→10 全流程并直接产出报告，**中途不停下来征询用户**；唯一允许中止回问的情形 = base 分支无法确定 / 命令参数歧义 / 范围内无变更。大 diff（数百文件、上万行）按"分批全覆盖"自动跑完，不因体量或"先确认一下"暂停。"建立上下文"明确为 agent 自读文档的内部前置，不是交互节点。
- brg `SKILL.md` version → 0.2.9；plugin/manifest → 0.2.9。

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
