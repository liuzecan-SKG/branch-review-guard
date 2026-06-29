# Branch Review Guard

Branch Review Guard 是一个**提测/上线前整分支综合代码评审编排器**。它在合并前对一条功能分支（相对主分支的累计变更）做多维度 code review，给出可发布性结论，并产出一份面向开发与测试的中文报告。

定位：**编排器，不是单体脚本**。它统一调度多个专项 reviewer，并**复用**已安装的 `api-change-guard`（API/兼容/影响/回归）和 `endpoint-perf-review`（性能），只补齐缺失维度（正确性/Bug、设计/可维护性、安全、测试、可观测/运维、i18n）并做汇总去重。

核心是**栈无关**的：通用 checklist 不绑定任何框架；技术栈/项目特有的"坑"与降噪校准通过可插拔的 `rules/` 规则包注入。

## 为什么需要它

- 单条功能分支提测前，改动常达数百文件、上万行。人/AI 对 >400 行做线性评审时缺陷检出率断崖下跌（SmartBear/Cisco 实证）。
- 单点工具各看一面：`api-change-guard` 看影响面、`endpoint-perf-review` 看单接口性能，但没有"一次性、全维度、给可发布性结论"的入口。
- 本工具用"自动化先行 → 建立上下文 → 分批全覆盖 → 按风险聚焦 → 显式声明覆盖"的策略，把"上万行 diff"压成"按优先级排序的发现清单 + 阻塞项"。

## 仓库结构

```text
branch-review-guard/
  README.md                          # 本文件：定位、使用、限制
  SKILL.md                           # 通用 Agent 正本（Cursor / Claude Code / 其他）
  CHANGELOG.md
  ROADMAP.md
  prompts/
    orchestrate-branch-review.md     # 编排主流程：分批、调度、风险聚焦、弹性复用
    review-correctness.md            # 正确性/Bug（空指针·边界·并发·幂等·事务）
    review-design.md                 # 设计/可维护性/可扩展性 + 可读性/质量
    review-security.md               # 鉴权/越权·注入·敏感信息·校验·依赖漏洞
    review-tests.md                  # 测试覆盖/断言质量/可测性
    review-observability.md          # 日志/指标/超时降级/运维就绪 + i18n
    consolidate-report.md            # 汇总去重 + 优先级 + 覆盖率 -> 单份报告
  templates/
    report-template.md               # 综合评审报告模板
  examples/
    sample-branch-review-report.md   # 样例报告（示意，非真实结论）
  reports/                           # 生成的报告（.gitignore，仅保留 .gitkeep）
```

安装后 `SKILL.md` 镜像到 `.cursor/skills/branch-review-guard/SKILL.md` 与 `.claude/skills/branch-review-guard/SKILL.md`。**正本是 `tools/branch-review-guard/SKILL.md`，改完同步两个镜像。**

## 规则机制（可插拔，栈无关核心）

核心 skill 不内联任何技术栈的特有坑；它们被外置到 `rules/` 规则包，运行时按维度匹配后叠加：

- `rules/baseline/`：**默认开启**，栈无关的通用规则与降噪校准。
- `rules/skg-spring/` 等**可选栈包**：默认关闭；同栈团队启用后获得机制级深度。
- 缺包时对应深度自然缺席，**通用 checklist 照常全跑**，不报错。

开关由 `rules/config.yaml` 控制；规则文件 schema 与消费方式见 `rules/README.md`。**为自己的技术栈加规则包**：复制一个现有栈包目录为 `rules/<your-stack>/`，按 schema 写规则并在 `config.yaml` 启用即可，核心 skill 无需改动。

## 可移植性

纯"Agent 规则 + Git 命令"，不依赖 Python，也**不依赖任何 IDE 自带的 `/review` 类命令**。只需要 Git + 一个能读文件、执行命令、写 Markdown 的 AI Agent。

- 支持子代理的 Agent（Cursor 的 explore/Task 等）：每批/每维度并行派子代理。
- 不支持子代理的 Agent：顺序多轮，结果一致只是更慢。

## 命令与使用

- `/branch-review-guard` —— 默认 = `branch`，分支相对 base 累计变更全维度评审（最常用）
- `/branch-review-guard branch [--base <分支>] [--dimensions bug,security,...]`
- `/branch-review-guard module <模块名>` —— 只深审某模块
- `/branch-review-guard diff` —— 仅未提交变更
- `/branch-review-guard recent <N>` —— 最近 N 个提交

slash command 未识别时直接说：

```text
读取 tools/branch-review-guard/SKILL.md，按其中流程对当前分支相对主分支做提测前综合评审。
```

## 输出

- 项目内生成的 Markdown 报告（优先 `tools/branch-review-guard/reports/`，否则项目根 `branch-review-reports/`），命名 `branch-review-guard-<mode>-<shortSha>-<timestamp>.md`。
- 结论先行（可发布性：阻塞/有条件通过/通过 + Top 风险）、分维度发现（带 `file:line` 证据与 `P0/P1/P2/Nit` 优先级）、高风险专题、API/兼容/回归、性能与可靠性、测试评估、可观测/运维、i18n、阻塞项清单、待人工确认项、分析覆盖范围与未覆盖风险。

## 与其它工具的关系

- **api-change-guard**：本工具的"API/兼容/影响/回归"维度通过**弹性路径解析**调用它的 `branch` 模式（`tools/` → `.cursor/skills/` → `.claude/skills/`），不重复实现；未安装则该维度在报告中声明未覆盖。单独想做影响面分析时仍可独立用 `api-change-guard`。
- **endpoint-perf-review**：本工具仅对高风险接口（同样弹性解析）调用它做性能复盘；未安装则声明未覆盖。单独想优化某个接口时仍可独立用 `endpoint-perf-review`。
- **`rules/` 规则包**：各维度 reviewer 的栈特有判定以启用的规则包为准（baseline 默认 + 可选栈包）。

## 护栏（可信度）

- 自动化分级：L1 自动定论；L2 给"证据+优先级"并标"待人工确认"；L3（真实性能/并发/迁移）只给"需运行时验证项"，**禁止下"已验证通过"**。
- 区分事实/推测/待确认，不编造调用方。
- 强制声明分析覆盖范围与未覆盖风险，绝不把没读的当已评审。

## 已知限制

- 评审质量取决于可获得的 diff、文件证据与上下文文档；多行签名、深层泛型 DTO、跨服务 RPC 调用方可能被标为待人工确认。
- 性能、并发、迁移等运行时结论需开发用压测 / `EXPLAIN` / 故障注入自行验证。
- 自动化先行（编译/测试/SCA）依赖本机环境，命令不可用时会跳过并在报告中说明。
- 栈特有的机制级深度取决于启用的规则包；未启用对应栈包时只跑通用 checklist。

## 误判记录

工具输出不准确时，按以下格式记录，便于迭代 SKILL / prompt / 规则：

```markdown
### Case: <短标题>
- Input: 分支 / 模块 / diff 摘要
- Wrong output: 工具输出了什么错误结论
- Expected output: 评审期望的正确结论
- Fix rule: 需要更新的 SKILL 规则、prompt 规则、护栏，或 rules/ 规则条目
```
