# Rules（可插拔规则机制）

本目录把"项目/技术栈特有的评审知识"从评审核心里**外置**出来，做成可逐条开关、可调严重度、可按栈匹配的规则包。核心 skill（branch-review-guard / api-change-guard / endpoint-perf-review）保持**栈无关**，运行时加载本目录中**已启用**的规则并叠加应用。

## 规则包（pack）

- `baseline/`：**默认开启**，栈无关的通用规则与降噪校准。
- `skg-spring/`：**默认关闭**的可选包，针对 SKG Health Global 技术栈（Spring Boot 3 / Dubbo / MyBatis-Plus / MongoDB 自研事务 / Sa-Token / RocketMQ）。同栈团队开启它即可获得机制级深度。
- `discover-new/`：**默认关闭**的团队沉淀区——`distill`/`rule` 反馈闭环产出、经人工确认后的规则落在这里。与上游作者预置的 `skg-spring/` **解耦**：升级插件时两者互不覆盖，也便于区分"作者预置 vs 本团队实测沉淀"。要生效在 `config.yaml` 手动开。
- 团队可新增自己的包目录（如 `rules/<your-stack>/`），按同一 schema 写规则。

启用哪些包由 `rules/config.yaml` 控制（安装器会按 `--rules` 写入）。

### 自动识别启用（auto_enable）

`enabled: false` 的栈包可配置 `auto_enable.project_markers`（字符串列表）。评审加载规则包时按标记探测目标项目——任一标记命中**仓库根目录名 / 模块目录名 / `pom.xml` 等构建文件的 groupId/artifactId** 即视为同栈项目，该包**本次运行自动启用**：

- 只影响当次评审，**不修改 `config.yaml`**；报告"已启用规则包"处注明"（自动识别启用）"。
- 优先级：显式 `enabled: true` > auto_enable 命中 > 默认关闭；`severity_overrides` / `disabled_rules` 照常生效。
- 探测只做**确定性字符串匹配**，不做"看起来像同栈"的模糊推断——宁可让用户显式开，不误开别人的项目。

## 规则文件 schema

每条规则是一个 markdown 文件，frontmatter 为元数据，正文为方法。

```markdown
---
id: skg-spring/txn-multitransactional-escape   # 全局唯一，pack/短名
pack: skg-spring                                # baseline | skg-spring | <your-stack>
type: finding                                   # finding（要查的问题） | calibration（降噪/绕过）
dimension: correctness                          # correctness|design|security|tests|observability|api|performance
severity: P0                                    # 默认严重度建议：P0|P1|P2|Nit（calibration 用 - ）
enabled: true                                   # 包内可逐条关
applies_to:                                     # 匹配器；省略/留空 = 该包启用时一律适用
  languages: [java]
  frameworks: [spring, mongodb]
  paths: ["**/*.java"]
summary: 一句话：这条规则在查/校准什么
---

## 识别要点
- 怎么从 diff/代码里识别命中（模式、注解、调用形态）。

## 取证方式
- 命中后要给的证据（file:line + 为什么），以及如何判真伪（避免误报）。

## 修法
- 推荐改法（finding 用）。

## 校准动作
- calibration 专用：命中后怎么处理（直接越过/降级；是否计入 P0/P1；是否进待人工确认）。
```

## 核心如何消费规则（reviewer 行为）

每个维度 reviewer 在跑通用 checklist 的同时：

1. **加载**：读取 `rules/config.yaml` 里 `enabled: true` 的包，外加 `auto_enable` 标记命中当前项目而运行时启用的包（见上节）；取其中 `dimension` 匹配本维度、且 `applies_to` 匹配当前仓库（语言/框架/路径）的规则。
2. **应用 finding 规则**：按"识别要点 + 取证方式"在本批文件里找命中；命中则按 `severity` 产出一条发现（`[P*] <维度> — 问题 — file:line — 影响 — 建议`），并按"取证方式"判真伪、降误报。
3. **应用 calibration 规则**：按"校准动作"对相应发现类做降噪（直接越过 / 降级），优先级高于 finding 的默认定级。
4. **缺包降级**：某栈包未启用时，对应的机制级深度自然缺席——这是预期；核心通用 checklist 仍照常跑。不要因为"没装某包"就报错。

## 严重度校准

`severity` 只是默认建议。团队可在规则文件里直接改，或在 `rules/config.yaml` 里按 `id` 覆盖（`severity_overrides`）。汇总阶段（consolidate）以"规则最终严重度 + calibration 动作"为准。

## 反馈闭环（可选，配合 ROADMAP #4）

被开发反复标"忽略/误报"的规则，建议在其 frontmatter 调低 `severity` 或置 `enabled: false`，或新增一条 `type: calibration` 规则把该类绕过。把处置记录留在 `rules/<pack>/FEEDBACK.md`。
