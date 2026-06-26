# API Change Guard 变更影响分析报告

> 本报告为**示意样例**，仅用于展示报告结构与措辞，**非真实分析结论**。示例采用栈无关的通用接口；默认测试骨架以 Java/Spring 示意，其它栈生成等价骨架。

## 结论先行

- 是否影响已上线功能: 可能影响老版本客户端 / 老调用方的请求体。
- 是否需要回归测试: 需要，重点回归保存接口和老版本请求体。
- 高风险影响点: 新增必填字段。
- 重点回归范围: `POST /api/v1/preferences`、偏好保存链路、参数校验链路。
- 是否需要客户端/其他后端服务配合: 需要确认调用方是否补传新增字段。

## 变更影响范围

### 已有功能影响

- 新增字段 `locale`（String，必填，含义：语言区域）。依据：新增字段；校验注解 `@NotBlank`
- 新增字段 `theme`（Integer，必填，含义：主题，枚举 0/1/2）。依据：新增字段；校验注解 `@NotNull`、`@Min(0)`、`@Max(2)`

### 新增功能影响

- 未识别新增功能入口，主要是已有保存接口请求契约变化。

### 端侧/调用方影响

- 移动端 / Web 前端: 高概率。依据：接口为偏好保存，请求体由前端构造
- 其它后端服务: 中概率。依据：若有服务通过 RPC/HTTP 调用该接口需确认是否补传新字段
- 管理后台: 低概率。依据：该接口为保存用户偏好，后台可能仅查询展示

### 后端链路影响

- 对外入口入参、请求 DTO 校验、保存逻辑链路都需要回归。

### 数据影响

- 新增字段可能影响请求数据校验和后续持久化/展示逻辑。

## 回归测试建议

### 必须回归

- `save_shouldSuccess_whenRequestValid`: 传入完整合法参数，预期返回成功响应
- `save_shouldFail_whenLocaleMissing`: 缺少必填字段 `locale`，预期参数校验失败或返回业务错误码
- `save_shouldFail_whenThemeMissing`: 缺少必填字段 `theme`，预期参数校验失败或返回业务错误码

### 建议回归

- `save_shouldFail_whenThemeOutOfRange`: `theme` 传入 -1 或 3，预期参数校验失败或返回业务错误码

### 可不回归

- 与该保存接口无调用关系的纯查询页面可不作为重点回归。

## 兼容性风险

### 请求参数兼容性

- 新增必填字段 `locale`，老版本客户端或调用方未传该字段时可能请求失败。依据：新增 `@NotBlank` 字段
- 新增必填字段 `theme`，历史请求体为空或字段缺失时会触发参数校验。依据：新增 `@NotNull` 字段

### 返回结构兼容性

- 返回类型未变化。

### 枚举/状态值兼容性

- `theme` 枚举值含义（0/1/2）需与客户端约定一致。

### 校验规则兼容性

- 新增必填校验，需要确认老版本兼容策略。

### 数据兼容性

- 新字段可能影响历史数据补录或空值处理。

## 变更事实摘要

### 新增接口/端点

- 未识别新增接口/端点。

### 修改接口/端点

- `POST /api/v1/preferences` 请求字段契约变化。

### 新增/修改契约字段

- 新增 `locale`、`theme`。

### 新增/修改方法逻辑

- 未识别方法逻辑变化。

### 数据访问 / 转换 / RPC 客户端变化

- 未识别相关变化。

## 关键链路分析

### 调用入口

- `POST /api/v1/preferences`

### 核心处理逻辑

- 对外入口接收入参后进入保存逻辑。

### 数据转换链路

- 需确认新字段是否被完整传递与使用。

### 持久化/缓存/MQ/远程调用影响

- 需确认新增字段是否持久化或仅用于校验。

## 测试点清单

### 正常场景

- 完整合法参数保存成功。

### 异常场景

- 缺少 `locale`、`theme`。

### 边界场景

- `theme` 非法枚举值（-1 / 3）。

### 历史兼容场景

- 老版本请求体不传新增字段。

### 回归场景

- 回归偏好保存链路与调用方请求体构造。

## 分析覆盖范围

- 分析模式与范围：示意（实际报告需写明 mode / base 分支 / commit 范围 / diff 命令）
- 源码变更文件数：示例未统计
- 已展开分析：保存接口和请求 DTO 字段
- 摘要分析：无
- 未展开分析：无
- 已排除测试文件：测试目录与测试命名（如 `src/test/**`、`*Test.java` 等）
- 规则包状态：示意——未启用栈特有 `dimension: api` 规则包，栈专有协议未做机制级深度检查

## 未覆盖风险

- 示意报告未包含真实调用方扫描，需人工确认调用方范围。

## 测试骨架

> 默认 Java/Spring（JUnit 5 + MockMvc）示意；其它栈生成等价的接口测试骨架。

```java
@SpringBootTest
@AutoConfigureMockMvc
class PreferenceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void save_shouldSuccess_whenRequestValid() throws Exception {
        String body = """
                {
                  "locale": "zh-CN",
                  "theme": 1
                }
                """;

        // 需要的依赖 Mock / 鉴权请由开发或规则包补充
        mockMvc.perform(post("/api/v1/preferences")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }
}
```

## 接口请求样例

> curl / Apifox / Postman 通用形态；鉴权 Header 按项目约定补充。

```bash
curl -X POST "http://localhost:8080/api/v1/preferences" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
  "locale": "zh-CN",
  "theme": 1
}'
```

## 待人工确认项

- 是否允许老版本客户端不传 `locale`，需要产品和接口负责人确认。
- `theme` 的枚举含义需要和客户端约定保持一致。
- 测试骨架需要开发根据依赖补充 Mock 和业务错误码 / 鉴权断言（或由规则包提供模板）。

## 次要代码质量提示

- 未输出完整代码质量评审；仅提示可能影响功能正确性的事项。
