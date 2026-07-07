# Branch Review Guard

覆盖**设计 + 评审**全链路的 Claude Code 插件：动手写码前用 **design-panel** 多视角出方案、提测/上线前用 **branch-review-guard** 对**整条功能分支**做多维度综合评审、给出**可发布性裁决**。

- 🎨 **方案设计擂台**（design-panel）：写码前并行派 N 个互不可见的设计代理从不同价值取向独立出案，对承重论断做 file:line 级对抗质证，裁判打分嫁接——产出对比表 + 推荐方案 + 精炼设计稿，从"单 agent 一把梭"逼近项目最优解。
- 🎯 **整分支 · 强制全覆盖**：上万行也分批读完，报告显式声明覆盖率，绝不把没读的当已审。
- 🧩 **多维并行**：正确性 / 设计 / 安全 / 测试 / 可观测 / i18n + API 兼容 + 接口性能；内置 **10 个只读子代理**（评审 7：5 维度+怀疑者+批评家；设计 3：设计代理+怀疑者+裁判）并行、上下文隔离。
- 🥊 **对抗验证降误报**：每条 P0/P1 经 3 视角怀疑者投票（证据/规则/触发路径），反驳须给 file:line 级反证；阻塞清单基本免人工甄别。收尾另有完整性批评家给覆盖率独立对账。
- ⚖️ **可发布性裁决**：阻塞 / 有条件通过 / 通过 + Top 风险 + must-fix 清单，直接支撑 go/no-go。
- 🛡️ **诚实边界**：运行时项（性能 / 并发 / 迁移）只给"需验证项"，**绝不下"已通过"**。
- 🔌 **可插拔规则**：栈无关核心 + 可开关栈包（`baseline` 默认开、`skg-spring` 默认关但**同栈项目自动识别启用**，标记可配）。
- 📦 **一键启停 / 版本 / 部门复用**：装·停·升级一条命令，团队随分支共享。

## 安装

### A. Claude Code 原生插件（推荐）

本仓库即一个 **Claude Code 插件 + 单插件 marketplace**（`.claude-plugin/`），一键装全套（4 skill + 10 只读子代理 + `/branch-review-guard:review`、`:diff`、`:distill`、`:rule`、`:design` 命令），支持启停/版本/部门复用。

- **VSCode 扩展**：`/plugins` → **Marketplaces** 标签填 `liuzecan-SKG/branch-review-guard` 点 **Add** → **Plugins** 标签点 **Install**。
- **CLI（终端 `claude`）**：

  ```text
  /plugin marketplace add liuzecan-SKG/branch-review-guard
  /plugin install branch-review-guard@branch-review-guard
  ```

**装好后强烈建议开启 auto-update**（否则更新要手动，见 [更新](#更新)）。在 `.claude/settings.json`（项目级，随分支共享给同事）或 `~/.claude/settings.json`（用户级，仅本机）写：

```json
{
  "extraKnownMarketplaces": {
    "branch-review-guard": {
      "source": { "source": "github", "repo": "liuzecan-SKG/branch-review-guard" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": { "branch-review-guard@branch-review-guard": true }
}
```

存盘后用 `Ctrl+Shift+P` → **Developer: Restart Extension Host** 让其生效（见[更新](#更新)的生效说明）。

### B. 其它 Agent（Cursor / Codex / Cline 等）

插件格式仅 Claude Code 认；其它 Agent 用安装器或直接读 skill：

- **安装器**（把文件装进项目，版本感知覆盖 + 备份）：让 Agent 读 `install/SKILL.md` 按其流程安装。详见 [INSTALL.md](INSTALL.md)。
- **只想用不想装**：让 Agent 直接读 `skills/branch-review-guard/SKILL.md`（自动复用 `api-change-guard`、`endpoint-perf-review`、`rules/`）。

跨 Agent 说明见 [AGENTS.md](AGENTS.md)。三种安装路径的取舍、版本与更新机制的来龙去脉见 [CHANGELOG.md](skills/branch-review-guard/CHANGELOG.md)。

## 使用

命令 = **`/branch-review-guard:review [模式] [选项]`**。

> Claude Code 插件命令带命名空间 `<插件名>:<命令名>`，故规范写法是 `/branch-review-guard:review`（裸 `/branch-review-guard` 不识别）。输入 `/` 看自动补全菜单即可选到它。非插件形态（Cursor/安装器）或不想记命令时，直接对 Agent 说"对当前分支做提测前综合评审"亦可。

**留空 = `branch` 全量模式**（提测/上线卡点，最常用）：

```text
/branch-review-guard:review                          # branch：整分支 vs master 累计变更，全维度（默认）
/branch-review-guard:review branch --base develop    # 改对比基线（缺省自动探测 master/main）
/branch-review-guard:review module <模块名>           # 只深审某模块（缩范围、提精度）
/branch-review-guard:review diff                     # 仅未提交变更（边写边查，最快）
/branch-review-guard:diff                            # 同上，diff 模式的独立命令入口（等价 review diff）
/branch-review-guard:review recent 3                 # 最近 N 个提交
```

**选项**：`--base <分支>`（对比基线）、`--dimensions <逗号分隔>`（只跑部分维度）、`--thorough`（高风险批次追加"新鲜眼"二轮扫描，连续一轮无新发现即停）。维度取值：`bug`（正确性）`design`（设计/质量）`security`（安全）`test`（测试）`api`（兼容/影响/回归）`perf`（性能）`observability`（可观测/运维/i18n）。例：

```text
/branch-review-guard:review branch --dimensions bug,security
/branch-review-guard:review module skg-health-global-user --dimensions api,perf
```

**配套命令（反馈闭环）**：

- `/branch-review-guard:distill [N]`：从本地最近 N 份评审报告**按代码实例**聚类重复发现，生成 `rules/` 候选规则草稿（漏报→finding、误报→calibration），人工确认后提交回本仓库生效——评审越用越准，教训还能反哺开发侧。会把"一直没改的老问题"分诊为**遗留项**单列（不误当漏报固化成规则），交你决定排期修或转豁免。
- `/branch-review-guard:rule <描述> [--type finding|calibration]`：一句话**手动**快捷加一条规则草稿（绕过 distill 的 ≥2 次阈值、由人担保泛化）；适合把遗留项一键转 calibration，或一眼确信要规则化的强 case。同样走"草稿→人工确认→提交生效"的关卡。

### 方案设计（写码前）

**`/branch-review-guard:design <需求描述>`** —— 动手写码前的多视角设计擂台：并行派 N 个互不可见的设计代理从不同价值取向（最小改动 / 长期可维护 / 风险与回滚 / 性能 / 复用）独立读代码出方案，对每案承重论断派怀疑者做 file:line 级对抗质证，裁判打分产出对比表 + 推荐方案 + 嫁接落选亮点的综合方案，并另出精炼设计稿（认可后移入 `docs/`，后续 `:review` 建立上下文会自动读取，形成"设计 → 评审"闭环）。选项：`--input`（需求文档）、`--module`（缩范围）、`--variants N`、`--quick`/`--thorough`（成本档位）。

### 典型时机

| 场景 | 命令 |
|---|---|
| 动手写码前出方案 | `/branch-review-guard:design <需求>`（多视角设计擂台，产出对比表+推荐+嫁接方案） |
| 提测/上线前卡点 | `/branch-review-guard:review` |
| 迭代期边写边查 | `/branch-review-guard:diff`（= `review diff`） |
| 聚焦某模块深审 | `/branch-review-guard:review module <名>` |
| 复核最近几个提交 | `/branch-review-guard:review recent <N>` |
| 只关心某几维 | `... --dimensions bug,security` |

### 它会做什么

1. 建上下文（读 `*_DESIGN.md`/`*_CONTRACT.md`/commit message）→ 自动化先行(L1) → 加载启用的 `rules/` 规则包 → 估规模分批（大 diff 强制全覆盖）。
2. **插件形态**：按批并行派发 5 个只读维度子代理（`bru-*`），上下文隔离；不支持子代理的环境自动顺序多轮。
3. 复用 `api-change-guard`（兼容/影响/回归）与 `endpoint-perf-review`（仅高风险接口性能）。
4. **对抗性验证**：每条 P0/P1 派 3 个视角的怀疑者（`bru-skeptic`）投票，反驳 ≥2 票否决、1 票降级标争议、0 票标"已对抗验证"；被否项留附录备查。
5. 汇总去重、统一定级（P0/P1/P2/Nit），再由完整性批评家（`bru-critic`）对账覆盖率与漏项后定稿，产出**一份中文报告**：可发布性结论 + Top 风险 + 分维度发现 + 阻塞清单（仅收经验证项） + 覆盖率声明。运行时维度只给"需运行时验证项"，不下"已验证通过"。

报告生成在项目内 `branch-review-reports/`（不存在即创建；若项目装有 `tools/branch-review-guard/reports/` 则沿用），命名 `branch-review-guard-<mode>-<shortSha>-<timestamp>.md`。

> 非 slash 环境/命令未识别：直接说"读取 branch-review-guard 的 SKILL.md 并对当前分支相对 master 做提测前综合评审"。

## 更新

**查当前已安装版本**（UI 不显示版本号）：

```bash
node -e "const d=require(require('os').homedir()+'/.claude/plugins/installed_plugins.json');for(const[k,v]of Object.entries(d.plugins))console.log(k,v[0].version)"
```

- **开了 auto-update**：每次启动自动 pull + 激活最新，无需任何操作（推荐，见[安装](#a-claude-code-原生插件推荐)）。
- **手动兜底**：VSCode `/plugins` → Marketplaces 刷新 → Plugins 对插件 Update/Install；CLI `/plugin marketplace update branch-review-guard` 再重装。

**让更新/配置变更生效**：`Ctrl+Shift+P` → **Developer: Restart Extension Host**（重启扩展宿主，比重启 VS Code 轻）。注意：VSCode 扩展里 `Reload Window` 往往**不足以**重载插件（常驻 agent 会话未重置），且 `/reload-plugins`、`/restart-agent` 等命令不可用——以 Restart Extension Host 为准。

> "刷新 marketplace ≠ 激活已安装插件"、"`version` 钉住需每次发布 bump" 等机制细节见 [CHANGELOG.md](skills/branch-review-guard/CHANGELOG.md)。

## 卸载

干净卸载，**项目内无残留**（插件仅缓存于 `~/.claude/plugins/cache`，从不往项目拷文件）：

- VSCode：`/plugins` → Plugins → 详情 → **Uninstall**（或 **Disable** 仅停用）。
- CLI：`/plugin uninstall branch-review-guard@branch-review-guard`（或 `/plugin disable ...`）。

## 迁移（项目里已有旧 skill 副本时）

若项目早前手工拷过/装过这些 skill 的旧本地副本，**插件会被旧副本遮蔽**（`/branch-review-guard` 命中旧版）。删除以下旧副本即可（`design-to-api` 等其它 skill 不动），插件自带最新版顶上：

```text
.claude/skills/{branch-review-guard,api-change-guard}
.cursor/skills/{branch-review-guard,api-change-guard,endpoint-perf-review}
.cursor/rules/{branch-review-guard,endpoint-perf-review}.mdc
tools/{branch-review-guard,api-change-guard}
```

> 遮蔽机制与安装器路径的"版本感知覆盖"对比见 [CHANGELOG.md](skills/branch-review-guard/CHANGELOG.md)。

## 它包含什么

- **branch-review-guard**（评审主 skill / 编排器）：分批全覆盖、按风险聚焦、L1/L2/L3 护栏、可发布性报告。
- **design-panel**（设计侧 skill / 编排器）：写码前多视角独立成案 + 对抗质证 + 裁判嫁接，产出对比表 + 推荐方案 + 精炼设计稿（移入 `docs/` 供 `:review` 建立上下文）；`requires: ["branch-review-guard"]`，共享 `rules/` 与 `reports/`。
- **api-change-guard**（依赖）：API/兼容性/影响范围/回归分析。
- **endpoint-perf-review**（依赖）：单接口性能调用链复盘。
- **可插拔规则 `rules/`**：核心栈无关；`baseline/`（默认开）+ `skg-spring/`（可选，Spring/Dubbo/MyBatis/Mongo/Sa-Token/RocketMQ 栈）。加自己的栈包：复制 `rules/skg-spring/` 为 `rules/<your-stack>/`，按 `rules/README.md` 写规则、在 `rules/config.yaml` 启用，核心 skill 无需改。

## 设计原则

自包含零依赖可移植 · 强制全覆盖 + 覆盖率声明 · 诚实边界（运行时维度只给"需验证项"）· 复用而非重造。完整架构与选型见随仓 `ROADMAP.md` 与维护方设计文档。

## 仓库结构

```text
branch-review-guard/
  .claude-plugin/  plugin.json  marketplace.json   # Claude Code 插件层
  commands/        review  diff  distill  rule  design   .md   # /branch-review-guard:<verb>
  agents/          bru-{correctness,design,security,tests,observability,skeptic,critic}.md
                   dsp-{designer,skeptic,judge}.md            # 评审 7 + 设计 3 = 10 只读子代理
  skills/          branch-review-guard/  design-panel/  api-change-guard/  endpoint-perf-review/
  rules/           config.yaml  baseline/  skg-spring/  discover-new/
  install/SKILL.md  manifest.json                  # 安装器路径（非 Claude Code Agent）
  cursor-rules/    *.mdc                            # 可选：Cursor 自动提醒
  AGENTS.md  INSTALL.md  README.md  LICENSE
```

## 许可

见 [LICENSE](LICENSE)。
