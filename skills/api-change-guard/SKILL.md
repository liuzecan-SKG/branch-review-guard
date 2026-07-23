---
name: api-change-guard
version: 0.2.6
description: 分析静态类型后端代码变更的影响范围、回归测试范围与 API/契约兼容性风险。支持未提交变更、功能分支相对主分支的累计 diff、最近 N 个提交，或当前作者本人的提交。核心栈无关；默认示例以 Java/Spring 为主，框架/协议特有的深度检查由启用的 rules 规则包（dimension=api）补充。当评审涉及控制器/路由、请求/返回 DTO/schema、RPC/IDL、消息契约、校验或序列化注解的 Git diff 时使用。
---

# API Change Guard

本 skill 用于在提测、评审或客户端联调之前，分析后端代码变更的影响范围。主要目标是判断新需求、bug 修复、字段变更、方法逻辑变更或新增方法是否会影响已上线功能，以及需要回归测试哪些范围。代码质量评审是次要内容。

本 skill 的**核心逻辑栈无关**：它分析的是"对外契约（请求 / 返回 / 枚举 / 校验 / 数据 / RPC / 消息）是否发生不兼容变化、影响哪些已上线功能、需要回归什么"。具体技术栈的深度识别（框架专有注解、统一返回包装类型、特有上报/协议类型等）由 `rules/` 中**已启用**且 `dimension: api` 的规则包补充（见 `## 规则包集成`）。默认示例以 **Java / Spring** 为主，其它静态类型后端栈（Go / TypeScript / C# / Kotlin / Python typed 等）由对应规则包扩展。

## 调用方式

任意 AI Agent 都可以通过阅读本文件并遵循下面的工作流程来使用本 skill。

建议的提示语：

- `按照 API Change Guard 的 SKILL.md，分析当前 git diff`
- `按照 API Change Guard 的 SKILL.md，分析当前分支相对 master 的累计变更`
- `按照 API Change Guard 的 SKILL.md，分析最近 3 个提交`
- `按照 API Change Guard 的 SKILL.md，只分析我本人在当前分支的提交`

命令：

- `/api-change-guard analyze diff` —— 未提交变更（默认）
- `/api-change-guard analyze branch` —— 分支相对 base 的累计变更，用于合并前评审
- `/api-change-guard analyze recent <N>` —— 最近 N 个提交
- `/api-change-guard analyze mine` —— 当前作者在本分支的提交（commit 口径）
- `/api-change-guard analyze controller <ControllerPath>` —— 指定单个对外入口文件（控制器/路由）
- `/api-change-guard analyze endpoint <ControllerPath> <ApiPath>` —— 指定单个接口/端点
- `/api-change-guard generate-test <ControllerPath> <ApiPath>`

## 工作流程

1. 确定分析模式（默认 `diff`）或命令类型 / 用户意图。
2. 按所选模式收集 Git 证据（见 `## 分析模式`）。同时收集报告元数据：`git rev-parse --short HEAD` 和当前时间戳。
3. 排除测试源码（见 `### 排除测试源码`）。
4. 加载规则包：读取套件 `rules/config.yaml` 中已启用的规则，取其中 `dimension: api` 且 `applies_to`（语言/框架/路径）匹配当前仓库的规则，准备在分析阶段叠加应用（见 `## 规则包集成`）。
5. 按下面的优先级和阈值规则，对变更的源码文件分组。
6. 按大 diff 上限和契约信号门槛，读取相关的对外入口 / 请求返回契约 / RPC 客户端 / 数据访问·转换·业务逻辑文件。
7. 直接以 Git diff 和文件内容作为静态证据分析影响，并叠加应用第 4 步加载的 `dimension: api` 规则。
8. 在项目内手动生成 Markdown 报告——优先 `tools/api-change-guard/reports/`（安装器路径已建则用之），否则项目根的 `branch-review-reports/`（不存在即创建）；命名风格：`api-change-guard-<mode>-<shortSha>-<timestamp>.md`。
9. 先回复生成的报告链接，再在其下粘贴完整报告正文。
10. 如需更深入分析，读取 `prompts/` 下对应的 prompt，并应用到收集到的 Git/文件证据上。
11. 用下面的稳定结构返回中文 Markdown 报告。

## 分析模式

四种 diff 收集模式。默认是 `diff`。每种模式对应一个命令。每种模式都仍然排除测试源码，并仍然遵循 `大 Diff 规则`、`报告结构（必备）` 和 `回复约定`。

在 Windows PowerShell 下，命令逐行执行；不要用 `&&` 连接。

> 下面命令中的 `'*.java'` 是**默认示例**（Java/Spring）。请替换为你技术栈的源码 glob（如 `'*.go'`、`'*.ts'`、`'*.cs'`、`'*.kt'`、`'*.py'`），可在一条命令里多次 `--` 传多个 pathspec；具体集合可由启用的规则包 / 项目约定补充。

### base 分支探测（branch / recent / mine 模式）

1. 若 `origin/master` 存在，用 `master`。
2. 否则若 `origin/main` 存在，用 `main`。
3. 否则用 `git symbolic-ref --short refs/remotes/origin/HEAD` 探测。
4. 否则让用户指定 base 分支。

一律先 `git fetch origin`，并一律对比 `origin/<base>`（不要用可能过期的本地分支）。

```bash
git fetch origin
git rev-parse --verify origin/master
# 不存在则尝试：git rev-parse --verify origin/main
# 仍不存在则：git symbolic-ref --short refs/remotes/origin/HEAD
```

### `diff` 模式（默认）—— 未提交变更

```bash
git diff -- '*.java'
git diff --cached -- '*.java'
git diff --name-only -- '*.java'
git diff --cached --name-only -- '*.java'
```

### `branch` 模式 —— 分支相对 base 的累计变更（合并前评审）

diff 用三点 `...`（自 merge-base 以来本分支引入的改动），log 用两点 `..`：

```bash
git fetch origin
git diff origin/master...HEAD -- '*.java'
git diff --name-only origin/master...HEAD -- '*.java'
git log origin/master..HEAD --oneline --no-merges
```

### `recent <N>` 模式 —— 最近 N 个提交

```bash
git diff HEAD~<N>...HEAD -- '*.java'
git diff --name-only HEAD~<N>...HEAD -- '*.java'
git log HEAD~<N>..HEAD --oneline
```

### `mine` 模式 —— 当前作者在本分支的提交（仅 commit 口径）

按作者切分累计 diff 在理论上无法逐行精确实现（补丁不可交换；重叠编辑和删除无法干净拆分）。请使用 commit 口径；绝不要编造一份「本人净改动 diff」。

```bash
git fetch origin
git config user.email
git log -p --no-merges --reverse --author="<email>" origin/master..HEAD -- '*.java'
git log --no-merges --author="<email>" origin/master..HEAD --name-only --pretty=format: -- '*.java'
```

使用 `mine` 时，报告必须声明以下限制（用中文）：

- 这是 commit 口径过滤，不是“本人净改动 diff”；多人改同一文件或同一行时无法精确切分。
- commit 口径可能包含中间态，以及之后被他人覆盖的改动。
- 影响分析与回归判断仍以分支累计 diff（`branch` 模式）为权威基准，`mine` 仅用于缩小关注范围。

## 回复约定

最终回复必须同时包含报告链接和报告正文。不要只返回链接。

所有面向用户的输出必须使用中文，包括进度说明、报告正文、分析依据、推理摘要、待人工确认项和后续建议。除非是代码标识符、命令、文件路径、类名、方法名、注解或源码引用，否则不要输出英文的章节说明。

严格按以下顺序：

1. 第一行：`报告文件：[<filename>](<relative-path>)`
2. 空行
3. 完整的 Markdown 报告正文，以 `# API Change Guard 变更影响分析报告` 开头

不要用摘要代替粘贴报告。如果报告很长，仍要粘贴 `报告结构（必备）` 要求的章节；必要时只压缩较长的代码块或请求样例。

## 分析优先级

按以下顺序分析：

1. 影响范围：本次变更影响到的已有接口/端点、已上线功能、客户端页面、后端链路、数据流、协议流。
2. 回归测试：需要重新测试的已上线功能和场景。
3. 兼容性风险：请求字段、返回结构、枚举/状态值、校验规则、持久化数据，以及老客户端/老调用方兼容性。
4. 变更事实：新增或修改的接口/端点、契约字段、方法、逻辑分支、数据访问/转换/RPC 客户端变化。
5. 待人工确认：无法从代码证明的调用方、配置、协议、历史数据和跨服务影响。
6. 次要代码质量提示：只提可能影响功能正确性的问题。不做完整代码评审。

## 大 Diff 规则

当变更的源码文件很多时，不要一次性分析整个 diff。采用「先分流、再限界、再抽样、最后明确未覆盖范围」。

### 文件优先级

按以下顺序分析（括号内为 Java/Spring 默认示例，其它栈替换为等价角色）：

1. 控制器 / 路由 / 对外入口（Controller / Router / Handler）
2. 请求 / 返回契约（DTO / VO / BO / Request / Response / schema）
3. RPC / 远程调用契约（Feign / Remote Client / gRPC stub / IDL）
4. 数据访问 / 转换 / 业务逻辑（Mapper / Convert / Service / Logic）
5. 其他源码文件

### 排除测试源码

始终排除测试源码与仅测试的 diff。常见命名/目录（按栈替换或补充）：

- Java：`src/test/**`、`*Test.java`、`*Tests.java`
- 其它栈示例：`*_test.go`、`*.spec.ts`、`*.test.ts`、`test_*.py`、`*Test.cs` 等
- 仅测试的 diff（只动测试文件的提交/改动）

### 阈值

- `<= 10` 个源码文件：全量分析。
- `11-30` 个源码文件：全量分析 控制器 / 请求返回契约 / RPC 契约文件；数据访问·转换·业务逻辑文件做摘要；其他文件仅列出。
- `> 30` 个源码文件：进入**分批扫描模式**（见 `### 大 diff 分批扫描`）。必须分批覆盖全部相关文件，**不得**因文件多就截断、把未读文件直接丢进未覆盖。

### 各类型读取上限

- 控制器 / 路由 / 对外入口：最多 10 个文件
- 请求 / 返回契约：最多 20 个文件
- RPC / 远程调用契约：最多 10 个文件
- 数据访问 / 转换 / 业务逻辑：最多 10 个文件
- 其他源码文件：默认不读取

### 契约信号门槛（API 关键词）

只有当非「对外入口」文件的 diff 命中以下任一**对外契约信号**时，才深度分析。核心信号（栈无关）：

- 路由 / 端点声明（HTTP method + path、RPC service/method、消息 topic/handler）
- 请求 / 返回绑定（请求体/参数绑定、返回类型/序列化 schema）
- 校验约束（必填 / 范围 / 格式 / 枚举约束）
- 对外数据契约（DTO / VO / schema / IDL 字段增删改、类型变化、枚举/状态值）
- RPC / 远程调用契约（client / stub / 接口签名变化）

常见关键词示例（Java/Spring；**具体框架注解由启用的规则包补充**）：

- `@RequestMapping`、`@GetMapping`、`@PostMapping`、`@PutMapping`、`@DeleteMapping`
- `@RequestBody`、`@RequestParam`、`@PathVariable`、`@ParameterObject`
- `@Schema`
- `@NotNull`、`@NotEmpty`、`@NotBlank`
- `FeignClient`

> 统一返回包装类型、栈特有上报/协议类型（如某些项目的采集 DTO、二进制长度注解）等具体关键词，由启用的 `dimension: api` 规则包补充。原 SKG 专有项（`CommonResult`、`DataCollectDto`、`@Watch4gDataLength` 等）已移至 `rules/skg-spring/`（默认关闭）。

### 大 diff 分批扫描（必须执行，不得截断）

`branch` 和 `recent` 的累计 diff 通常很大，容易触发上面的阈值。**绝不允许**因为"文件太多"就只分析一部分、把其余直接列入未覆盖。文件多时必须执行分批扫描，目标是全覆盖：

1. 估规模：`git diff --stat origin/<base>...HEAD`，拿到变更文件总数与完整列表。
2. 分批：把变更文件切成多批，每批控制在深度分析上限内（约 ≤ 20-30 个文件）。分批方式优先级：
   - 优先**按模块/包**（同一业务域的对外入口 / 契约 / 数据访问 / 逻辑放一批，便于跨文件推理）；
   - 或**按 commit**（`git log origin/<base>..HEAD --oneline`，每批一个或几个 commit）。
3. 逐批分析：对每一批独立按 `分析优先级` 分析，产出该批的局部结论。
   - 若当前 Agent 支持子代理，**推荐每批派一个子代理并行分析**（上下文隔离、互不挤占）；
   - 不支持则顺序多轮，一批做完再做下一批。
4. 汇总：把各批结论合并成**一份**报告，按 `报告结构（必备）` 输出，跨批去重 / 合并影响范围、回归建议、兼容性风险。
5. 覆盖范围：`## 分析覆盖范围` 必须写明变更文件总数、批次数、每批覆盖的文件数，使覆盖率逼近 100%。`## 未覆盖风险` **只**用于真正无法解析的复杂类型 / 跨仓库调用方等，**不得**用来装"因体量没读的文件"。

### 必备「分析覆盖范围」小节

每份报告必须包含 `## 分析覆盖范围`，内容含：

- 分析模式与范围（mode、base 分支、commit 范围、实际使用的 diff 命令）
- 源码变更文件数
- 已展开分析
- 摘要分析
- 未展开分析
- 已排除测试文件
- 规则包状态（启用了哪些 `dimension: api` 规则包；若未启用栈特有包，注明"栈专有协议未做机制级深度检查"）

### 必备「未覆盖风险」小节

如果有文件未被深度分析，必须包含 `## 未覆盖风险`，并列出可能仍含接口影响的文件。同时提醒评审者确认返回结构变化、契约转换遗漏、RPC/远程调用方变化和隐藏的逻辑分支变化。

## 报告结构（必备）

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

> `## 测试骨架` 默认按 Java/Spring（JUnit 5 + MockMvc）生成；其它栈生成等价的接口测试骨架。`## 接口请求样例` 用 curl / Apifox / Postman 形态。

## 分析规则

- 把 Git diff 和文件内容当作事实依据。
- 评审范围排除测试源码（见 `### 排除测试源码`）。
- 区分事实、推测和待人工确认项。
- 不要编造调用方。影响范围必须给出依据和概率。
- 重点提示新增必填字段、删除字段、类型变化、校验变化、枚举变化和返回结构变化。
- 对无法解析的复杂类型，输出待人工确认项，而不是静默忽略。
- 不要把注释掉的对外入口代码（控制器/路由）当作真实接口。
- 以后端可发布性为先：区分阻塞项、必测项和非阻塞确认项。
- 如启用了 `dimension: api` 的规则包，按其「识别要点 / 取证方式」叠加栈特有契约/协议检查（如统一返回包装类型的字段语义、特有上报/协议类型的字段顺序·长度·计数字段、框架专有注解、RPC/IDL 兼容规则）；未启用时只跑栈无关通用分析（见 `## 规则包集成`）。
- 生成的测试代码只是骨架。提示开发补充依赖 mock 和项目特定的错误码 / 鉴权断言（具体形态由规则包或开发补充）。

## 通用契约检查（栈无关）

在有证据时检查以下项（具体类型/注解形态由启用的规则包补充）：

- 接口返回是否使用项目约定的**统一响应结构**（统一包装类型的具体形态由规则包定义）。
- 请求参数在需要时是否带**校验约束**（必填 / 范围 / 格式 / 枚举）。
- 是否存在 **API 文档/契约描述**（OpenAPI / Swagger 注解、IDL、schema 等）。
- 当请求字段变为必填，或返回字段被删除/改类型时，提示**兼容性风险**。
- 对各类**调用方**（移动端 / Web 前端 / 管理后台 / 其它后端服务 / 设备上报链路）评估影响范围。

## 规则包集成

本 skill 核心栈无关。技术栈 / 项目特有的契约深度检查通过可插拔规则机制叠加，不写死在本文件里。规则机制与文件 schema 见 `rules/README.md`。

1. **加载**：读取套件 `rules/config.yaml` 中 `enabled: true` 的规则包，取其中 `dimension: api`、且 `applies_to`（语言/框架/路径）匹配当前仓库的规则。
2. **应用**：在静态分析时叠加这些规则的「识别要点 / 取证方式」，作为对外契约兼容性分析的栈特有补充。例如：统一返回包装类型的字段语义、特有上报/协议类型的字段顺序·长度·计数字段、框架专有注解、RPC/IDL 兼容规则。命中后按规则 `severity` 与 calibration 动作定级。
3. **缺包降级**：未启用任何栈包时，仅运行栈无关的通用契约分析——这是预期行为，**不报错**；在 `## 分析覆盖范围` 注明"未启用栈特有 api 规则包，栈专有协议未做机制级深度检查"。

> 示例：SKG Health Global 技术栈的统一返回 `CommonResult<T>`、采集契约 `DataCollectDto<T>`、手表/4G/蓝牙上报的 `@Watch4gDataLength`、Sa-Token 鉴权、Dubbo/Feign `Remote*` 命名等专有检查，集中在 `rules/skg-spring/`（默认关闭，同栈团队启用即可获得机制级深度）。
