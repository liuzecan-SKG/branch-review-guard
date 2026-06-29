# Branch Review Guard

提测/上线前对**整条功能分支**（相对 master 的累计变更）做多维度综合评审、给出**可发布性裁决**的 Claude Code 插件。

- 🎯 **整分支 · 强制全覆盖**：上万行也分批读完，报告显式声明覆盖率，绝不把没读的当已审。
- 🧩 **多维并行**：正确性 / 设计 / 安全 / 测试 / 可观测 / i18n + API 兼容 + 接口性能；内置 **5 个只读子代理**分维度并行、上下文隔离。
- ⚖️ **可发布性裁决**：阻塞 / 有条件通过 / 通过 + Top 风险 + must-fix 清单，直接支撑 go/no-go。
- 🛡️ **诚实边界**：运行时项（性能 / 并发 / 迁移）只给"需验证项"，**绝不下"已通过"**。
- 🔌 **可插拔规则**：栈无关核心 + 可开关栈包（`baseline` 默认开、`skg-spring` 可选）。
- 📦 **一键启停 / 版本 / 部门复用**：装·停·升级一条命令，团队随分支共享。

## 安装

### A. Claude Code 原生插件（推荐）

本仓库即一个 **Claude Code 插件 + 单插件 marketplace**（`.claude-plugin/`），一键装全套（3 skill + 5 维度子代理 + `/branch-review-guard:review` 命令），支持启停/版本/部门复用。

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
/branch-review-guard:review recent 3                 # 最近 N 个提交
```

**选项**：`--base <分支>`（对比基线）、`--dimensions <逗号分隔>`（只跑部分维度）。维度取值：`bug`（正确性）`design`（设计/质量）`security`（安全）`test`（测试）`api`（兼容/影响/回归）`perf`（性能）`observability`（可观测/运维/i18n）。例：

```text
/branch-review-guard:review branch --dimensions bug,security
/branch-review-guard:review module skg-health-global-user --dimensions api,perf
```

### 典型时机

| 场景 | 命令 |
|---|---|
| 提测/上线前卡点 | `/branch-review-guard:review` |
| 迭代期边写边查 | `/branch-review-guard:review diff` |
| 聚焦某模块深审 | `/branch-review-guard:review module <名>` |
| 复核最近几个提交 | `/branch-review-guard:review recent <N>` |
| 只关心某几维 | `... --dimensions bug,security` |

### 它会做什么

1. 建上下文（读 `*_DESIGN.md`/`*_CONTRACT.md`/commit message）→ 自动化先行(L1) → 加载启用的 `rules/` 规则包 → 估规模分批（大 diff 强制全覆盖）。
2. **插件形态**：按批并行派发 5 个只读维度子代理（`bru-*`），上下文隔离；不支持子代理的环境自动顺序多轮。
3. 复用 `api-change-guard`（兼容/影响/回归）与 `endpoint-perf-review`（仅高风险接口性能）。
4. 汇总去重、统一定级（P0/P1/P2/Nit），产出**一份中文报告**：可发布性结论 + Top 风险 + 分维度发现 + 阻塞清单 + 覆盖率声明。运行时维度只给"需运行时验证项"，不下"已验证通过"。

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

- **branch-review-guard**（主 skill / 编排器）：分批全覆盖、按风险聚焦、L1/L2/L3 护栏、可发布性报告。
- **api-change-guard**（依赖）：API/兼容性/影响范围/回归分析。
- **endpoint-perf-review**（依赖）：单接口性能调用链复盘。
- **可插拔规则 `rules/`**：核心栈无关；`baseline/`（默认开）+ `skg-spring/`（可选，Spring/Dubbo/MyBatis/Mongo/Sa-Token/RocketMQ 栈）。加自己的栈包：复制 `rules/skg-spring/` 为 `rules/<your-stack>/`，按 `rules/README.md` 写规则、在 `rules/config.yaml` 启用，核心 skill 无需改。

## 设计原则

自包含零依赖可移植 · 强制全覆盖 + 覆盖率声明 · 诚实边界（运行时维度只给"需验证项"）· 复用而非重造。完整架构与选型见随仓 `ROADMAP.md` 与维护方设计文档。

## 仓库结构

```text
branch-review-guard/
  .claude-plugin/  plugin.json  marketplace.json   # Claude Code 插件层
  commands/        branch-review-guard.md          # /branch-review-guard
  agents/          bru-{correctness,design,security,tests,observability}.md
  skills/          branch-review-guard/  api-change-guard/  endpoint-perf-review/
  rules/           config.yaml  baseline/  skg-spring/
  install/SKILL.md  manifest.json                  # 安装器路径（非 Claude Code Agent）
  cursor-rules/    *.mdc                            # 可选：Cursor 自动提醒
  AGENTS.md  INSTALL.md  README.md  LICENSE
```

## 许可

见 [LICENSE](LICENSE)。
