---
id: discover-new/calibration-dead-defense-null-branch
pack: discover-new
type: calibration
dimension: correctness
severity: "-"
enabled: true
applies_to:
  languages: [java]
  frameworks: []
summary: 报"判空缺失/null 绕过分支"前必须先追值的工厂/来源方法是否永不返回 null（miss 时兜底 new 默认对象是常见模式），死防御路径不报缺陷
---

## 识别要点
- 拟报的发现形如："X 为 null 时绕过了后续归一化/校验/拦截"、"缺少对 X 的判空"、
  "isNull(X) 分支处理不当"——其中 X 来自某个**查询/工厂方法**的返回值。
- 常见模式：查询类 service 对 miss 情形不返回 null，而是**兜底构造默认对象**
  （如 cache miss → 远程回源 → 仍 miss 时 `new XxxEntity().setYyy(安全默认值)`），
  调用方拿到的引用恒非 null，其 isNull 分支实为死防御代码。

## 校准动作
- 报告前**先追来源方法的全部 return 路径**（含缓存 miss、远程回源失败的兜底分支）：
  - 若所有路径都不返回 null → 该"绕过/缺失"发现**不成立，不报**；相应 isNull 死防御
    分支也不按"处理不当"报缺陷（可选择按代码整洁 Nit 提示删除，不定级）。
  - 对已报发现做对抗复核时，同样以此法验证；据此翻案他人"正例"声明前，须先确认
    来源方法确有 null 路径，否则翻案本身是误报。
- 取证纪律：结论必须给出来源方法的 file:line 级 return 路径证据，不得凭方法名推断。
- 豁免边界（哪些情形**不豁免**）：
  - 来源方法存在**任一**返回 null 的路径（含异常吞掉后返回 null、Map.get 直传）→ 照常报。
  - 兜底对象的**字段**可能为 null（对象非 null 但字段没赋值）导致后续 NPE → 那是真问题，
    不在本校准范围。
  - 跨模块/跨 RPC 边界的返回值（Dubbo 反序列化可产生 null）不适用"永不为 null"推定，
    除非契约与实现两侧都核实。
