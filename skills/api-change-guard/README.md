# API Change Guard

API Change Guard 用于分析**静态类型后端**代码变更的影响范围，并生成面向后端、客户端和测试同学的稳定报告。主要目标是判断代码变更是否影响已上线功能，以及需要回归测试哪些范围。

本工具**核心栈无关**：分析的是"对外契约（请求 / 返回 / 枚举 / 校验 / 数据 / RPC / 消息）是否发生不兼容变化"。具体技术栈的深度识别（框架专有注解、统一返回包装、特有上报/协议类型等）由可插拔规则机制（`rules/`，`dimension: api`）补充。默认示例以 **Java / Spring** 为主，其它栈（Go / TypeScript / C# / Kotlin / Python typed 等）由对应规则包扩展。

## 推荐目录结构

作为 branch-review-guard 套件的一个 skill，安装后目录结构如下：

```text
api-change-guard/
  README.md
  SKILL.md
  CHANGELOG.md
  prompts/
    analyze-api-change.md
    generate-test-cases.md
    generate-mockmvc.md
  examples/
    sample-api-change-report.md
  reports/
    .gitkeep
```

其中：

- `SKILL.md` 是通用 Agent 版本，适合 Cursor、Claude Code、Codex CLI 或其他能读取文件的 AI Agent。
- `README.md` 是安装和使用说明。
- `CHANGELOG.md` 记录版本变更。
- `prompts/` 是可选增强 Prompt。
- `examples/` 是示例报告（示意，非真实结论）。
- `reports/` 是生成报告的输出目录。
- 技术栈/项目特有的契约知识不在本 skill 内，而在套件的 `rules/`（见 `rules/README.md`）。

## 支持的输入

分析范围模式（默认 `diff`，每种能力都有独立命令）：

- 未提交变更（默认）：`/api-change-guard analyze diff`
- 功能分支相对主分支累计变更（合并前评估）：`/api-change-guard analyze branch`
- 最近 N 个提交：`/api-change-guard analyze recent <N>`
- 仅本人在本分支的提交（commit 口径）：`/api-change-guard analyze mine`

指定目标：

- 指定单个对外入口文件（控制器/路由）：`/api-change-guard analyze controller <ControllerPath>`
- 指定单个接口/端点：`/api-change-guard analyze endpoint <ControllerPath> <ApiPath>`

## 输出内容

- 生成到项目内报告目录的 Markdown 报告文件（优先 `tools/api-change-guard/reports/`，否则项目根 `branch-review-reports/`）
- 已上线功能影响范围总结
- 回归测试范围
- API 和业务链路变更摘要
- 栈特有契约 / 上报协议字段细节（由启用的 `dimension: api` 规则包补充）
- 对各类调用方（移动端 / Web 前端 / 管理后台 / 其它后端服务 / 设备上报链路）的影响范围推测
- 带证据的兼容性风险
- 边界场景和异常场景测试清单
- 接口测试骨架（默认 Java/Spring 的 JUnit / MockMvc；其它栈生成等价骨架）
- 可复制到 Apifox / Postman 的 curl 请求样例

## 安装和使用

本 skill 通常作为 branch-review-guard 套件的一部分安装（见套件 `INSTALL.md`）。也可单独使用，方式如下。

### 通用 Agent 使用方式

适用于任意能读取项目文件、执行 Git 命令、创建 Markdown 文件的 AI Agent。

1. 将 `SKILL.md`（及可选的 `prompts/`、`rules/`）放到目标项目中，例如：

```text
tools/api-change-guard/SKILL.md
```

2. 对 Agent 说：

```text
请读取 tools/api-change-guard/SKILL.md，并按照 API Change Guard 流程分析当前 git diff。
```

或者：

```text
按照 API Change Guard 的 SKILL.md，分析当前代码变更对已上线功能的影响范围。
```

### Cursor 使用方式

项目级安装：

```text
.cursor/skills/api-change-guard/SKILL.md
```

可以直接复制通用版 `SKILL.md` 到上述路径。然后在 Cursor 中输入：

```text
/api-change-guard analyze diff
```

如果 slash command 未被自动识别，也可以直接输入：

```text
请读取 .cursor/skills/api-change-guard/SKILL.md，并按照 API Change Guard 流程分析当前 git diff。
```

### Claude Code / Codex / 其他 Agent 使用方式

将 `SKILL.md` 放到项目根目录或工具目录，然后输入：

```text
读取 SKILL.md，并按 API Change Guard 流程分析当前 git diff。
```

如果项目里有多个 `SKILL.md`，建议明确路径：

```text
读取 tools/api-change-guard/SKILL.md，并按其中规则分析当前 git diff。
```

## 执行流程

本工具采用“通用 Agent 规则 + Git 命令分析”方案，不依赖 Python，也不需要额外本地运行时。只需要 Git 和一个能读取文件、执行命令、创建 Markdown 文件的 AI Agent 即可使用。

AI Agent 会根据分析模式收集 Git 证据（下面 `'*.java'` 为默认示例，按栈替换为对应源码 glob，如 `'*.go'`、`'*.ts'`、`'*.cs'`、`'*.kt'`、`'*.py'`）：

```bash
# 默认：未提交变更
git diff -- '*.java'
git diff --cached -- '*.java'

# 分支累计变更（合并前评估）：先 fetch，base 优先 master，兜底 main
git fetch origin
git diff origin/master...HEAD -- '*.java'
git log origin/master..HEAD --oneline --no-merges

# 最近 N 个提交
git diff HEAD~<N>...HEAD -- '*.java'

# 仅本人提交（commit 口径，先取 user.email 再填入 --author）
git config user.email
git log -p --no-merges --reverse --author="<email>" origin/master..HEAD -- '*.java'

# 报告元数据
git rev-parse --short HEAD
```

说明：

- base 分支优先 `master`，没有则 `main`，再没有用 `git symbolic-ref --short refs/remotes/origin/HEAD` 探测或让用户指定。
- 分支 / 最近 / 本人模式一定先 `git fetch origin`，且一定对比 `origin/<base>`，不用可能过期的本地分支。
- `git diff` 用三点 `...`（分叉点以来本分支引入的改动），`git log` 用两点 `..`。
- `analyze mine` 是 commit 口径过滤，不是“本人净改动 diff”；多人改同一文件无法精确切分，影响分析与回归判断仍以 `branch` 模式为权威基准。

然后 AI Agent 会读取相关的对外入口 / 请求返回契约 / RPC 客户端 / 数据访问·转换·业务逻辑文件，基于 Git diff 和文件内容分析影响范围，叠加应用 `rules/` 中已启用的 `dimension: api` 规则，在项目内报告目录（优先 `tools/api-change-guard/reports/`，否则项目根 `branch-review-reports/`）生成 Markdown 报告，并返回报告链接和报告正文。

报告文件名包含分析目标、当前 commit 短 SHA 和时间戳，例如：

```text
tools/api-change-guard/reports/api-change-guard-diff-a1b2c3d-20260605-182900.md
```

## 规则机制（可插拔）

技术栈/项目特有的契约检查不写死在本 skill，而是放在套件的可插拔规则机制里：

- 核心 skill 栈无关；运行时**加载并应用** `rules/config.yaml` 中已启用、`dimension: api` 且匹配当前仓库的规则。
- 缺包时降级为通用契约分析（不报错），并在「分析覆盖范围」注明。
- 要为自己的技术栈加深度检查：按 `rules/README.md` 的 schema 在对应规则包里新增 `dimension: api` 的规则即可，无需改本 skill。

> SKG Health Global 技术栈的专有检查（`CommonResult<T>`、`DataCollectDto<T>`、`@Watch4gDataLength`、Sa-Token、Dubbo/Feign `Remote*` 命名等）集中在 `rules/skg-spring/`（默认关闭）。

## 回复格式要求

最终回复必须同时包含报告链接和报告正文，不能只返回链接。

所有面向用户的输出必须使用中文，包括进度说明、报告正文、分析依据、推理摘要、待人工确认项和后续建议。代码标识符、命令、文件路径、类名、方法名、注解和源码引用可以保留原文。

固定顺序：

```markdown
报告文件：[<filename>](<relative-path>)

# API Change Guard 变更影响分析报告

...完整报告正文...
```

如果报告很长，也不能只总结报告；必须保留报告结构中的核心章节。必要时只能压缩较长的代码块或请求样例。

## 报告结构

```markdown
## 结论先行
## 变更影响范围
### 已有功能影响
### 新增功能影响
### 端侧/调用方影响
### 后端链路影响
### 数据影响
## 回归测试建议
### 必须回归
### 建议回归
### 可不回归
## 兼容性风险
### 请求参数兼容性
### 返回结构兼容性
### 枚举/状态值兼容性
### 校验规则兼容性
### 数据兼容性
## 变更事实摘要
### 新增接口/端点
### 修改接口/端点
### 新增/修改契约字段
### 新增/修改方法逻辑
### 数据访问 / 转换 / RPC 客户端变化
## 关键链路分析
### 调用入口
### 核心处理逻辑
### 数据转换链路
### 持久化/缓存/MQ/远程调用影响
## 测试点清单
### 正常场景
### 异常场景
### 边界场景
### 历史兼容场景
### 回归场景
## 分析覆盖范围
## 未覆盖风险
## 测试骨架
## 接口请求样例
## 待人工确认项
## 次要代码质量提示
```

## 大 Diff 分析规则

- `<= 10` 个源码文件：全量分析。
- `11-30` 个源码文件：全量分析 控制器/路由、请求返回契约、RPC 契约；数据访问·转换·业务逻辑做摘要分析；其他文件只列出。
- `> 30` 个源码文件：进入大 diff 分批扫描模式，必须分批覆盖全部相关文件，不得因体量截断。
- 文件优先级：控制器/路由、请求返回契约（DTO/VO/Request/Response/schema）、RPC/远程调用契约（Feign/Remote Client/gRPC stub/IDL）、数据访问·转换·业务逻辑（Mapper/Convert/Service/Logic）、其他源码文件。
- 非「对外入口」文件只有命中契约信号时才深度分析，例如路由声明、请求/返回绑定、校验约束、序列化 schema、RPC 接口签名；具体框架关键词由启用的规则包补充。
- 分支 / 最近模式分批：分支累计 diff 通常更大，先用 `git diff --stat origin/master...HEAD` 估规模；超过深度分析上限时，按 commit 或模块分批分析，而不是直接截断，避免漏掉非入口文件的核心逻辑改动。
- 在“分析覆盖范围”记录 commit 数、分析批次与规则包状态；真正无法解析的内容才列入“未覆盖风险”。

## 可靠性规则

- Git diff 和文件内容是事实依据。
- 测试源码不纳入评审范围（见 SKILL.md `### 排除测试源码`）。
- 注释掉的对外入口代码（控制器/路由）不视为真实接口。
- 报告应以影响范围为中心，先判断是否影响已上线功能，再补充代码质量提示。
- 必须明确回归测试范围。
- 对大 diff 或部分分析的 diff，必须输出分析覆盖范围和未覆盖风险。
- 栈特有契约/协议的深度检查由 `dimension: api` 规则包补充；未启用时降级为通用契约分析，并在覆盖范围注明。
- AI 结论必须区分事实、推测和待人工确认项。
- 无法解析的复杂类型必须写入待人工确认项，不能静默忽略。
- 生成的测试代码只是骨架，开发仍需补充依赖 Mock、项目特定鉴权和精确断言。
- 影响范围不是最终事实，报告必须给出概率和依据。
- 如果收集到的证据有限，仍需输出可读报告，并明确待人工确认项。

## 已知限制

- 本工具依赖 AI Agent 直接理解 Git diff 和源码文件，因此分析质量取决于可获得的 diff 和文件证据。
- 多行方法签名、深层泛型/嵌套契约可能需要人工复核。
- RPC 客户端、数据访问层和前端调用方分析可能会被标记为待人工确认。
- 生成的测试代码默认基于 Java/Spring（JUnit 5、Spring Boot Test、MockMvc）；其它栈生成等价骨架。项目特定的鉴权、租户 Header、依赖 Mock 需要开发自行补充，或由规则包提供模板。

## 误判记录

当工具输出错误或不够准确的结论时，建议按以下格式记录，便于后续优化 Skill 或对应规则包：

```markdown
### Case: <short title>

- Input: 对外入口路径、接口路径或 diff 摘要
- Wrong output: 工具输出了什么错误结论
- Expected output: 评审期望的正确结论
- Fix rule: 需要更新的 Skill 规则、Prompt 规则、规则包规则或人工确认规则
```
