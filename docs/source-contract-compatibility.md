# 书源执行契约与验证

本次以用户提供的 `wenku.json` 和 `光遇聚合.json` 为输入，不修改、复制或按站点识别原始定义。书源只负责声明规则或函数，运行时负责网络、会话、状态、编码和结果映射。

## 两种声明，共享执行基础

- Legado 规则：请求模板 → URL 脚本变换 → 请求选项/字符编码 → HTTP → 脚本/JSONPath/CSS/XPath 流水线 → 图书/目录/正文。
- HTML 函数：内联脚本契约 → `search/info/chapter/content` → 异步函数结果 → 同一图书/目录/正文模型。
- HTML 桥接通过既有 source script context 调用网络、cookie、缓存与文本接口；不建立绕开现有网络策略的第二个 HTTP 客户端。
- HTML 与规则源都按定义能力接入 `SourceRuntime`；功能识别不能依赖书源名称、域名或具体小说。
- 规则引擎语义变化时递增持久章节缓存版本，避免旧解析结果掩盖修复。

## 修改前证据

显式读取两个原文件运行搜索链路：

| 输入 | 失败阶段 | 观测 |
| --- | --- | --- |
| 文库 | 搜索请求解析 | `reading source request options must be a JSON object.`；尚未发出网络请求 |
| 光遇 HTML 聚合 | 导入能力识别 | capabilities 为空，不能进入搜索/阅读 |

文库 URL 包含请求选项后置 `@js:`；其搜索列表还组合 `<js>…</js>` 和 CSS。HTML 聚合定义异步函数并调用 `window.flutter_inappwebview.callHandler`，不能当作缺少 `ruleSearch` 的 Legado 源处理。

## 可复用范围

2026-09-27 对用户书资源目录顶层 11 个 JSON 的只读盘点：10,052 条源记录，按 `bookSourceUrl` 去重为 7,718 个身份。不同版本混存，以下均为**静态语法命中，不是在线成功率**：

| 契约 | 不同书源地址数 |
| --- | ---: |
| JavaScript 规则标记 | 3,841 |
| 请求 URL 后置 `@js:` | 24 |
| `<js>` 后续 CSS/XPath | 398 |
| HTML 函数容器 | 1 |

CSS/XPath 组合候选包括古典文学的 URL 后置脚本、红袖添香的远程 HTML → legacy CSS、熊猫看书的 JSON content → XPath。通用数组夹具另行覆盖脚本返回多个 HTML 根的语义，不能把静态候选自动算为列表执行成功。

下一优先级是 JSoup DOM 对象/集合生命周期：现有节点包装中的字符串重解析、集合方法与节点删除语义需要独立契约测试，再统一修复。不要据此追加站点特判。

## 重跑原始文件的在线链路

```sh
SOURCE_SAMPLE_PATHS='["/absolute/wenku.json","/absolute/光遇聚合.json"]' \
  flutter test --no-pub tool/source_sample_smoke_test.dart \
  --concurrency=1 --reporter expanded
```

工具以原文件导入，依次验证搜索、详情、目录与首章，任何阶段失败都会使测试失败；输出阶段和耗时。可以用 `SOURCE_SAMPLE_QUERY` 指定词、`SOURCE_SAMPLE_LIMIT` 限制源数量。它位于 `tool/`，不会向默认离线测试套件引入网络依赖。会话与偏好仅使用内存，不读取用户账号或写入应用登录态。`SOURCE_SAMPLE_CHAPTER_INDEX=1` 可改读目录第二项，避免只验证版权页。

站点可用性与引擎兼容必须分别记录：本次初查光遇配置接口返回 200，文库首页/登录页/搜索接口返回 403。无账号的离线测试不能证明登录后在线可读。


## 效率与隔离约束

- HTML 内联脚本和函数能力只解析一次并复用；LRU 最多保留 8 个文档、累计 100 万字符，避免无上限增长。
- 详情载荷缓存最多 1,024 本，切换登录态或关闭运行时会清理；目录复用已取得的详情。
- 只有 HTML 异步契约进入 Promise 等待，普通同步规则保持同步执行路径。
- 脚本调用携带独立 invocation ID；取消/超时后更换 JS runtime，后续排队源继续执行，旧异步回调不能写入新调用。
- 列表替换只执行一次，脚本返回的 HTML 片段保留表格上下文后再解析；不以增加站点分支掩盖执行顺序错误。

## 原始定义与在线验证结果

- 两个 opt-in 离线工具从环境变量读取原始文件，用合成 HTTP 响应验证原样脚本的搜索 → 详情 → 目录 → 正文；不将第三方源全文提交到仓库。
- 先前光遇在线实测：搜索返回 100 项，目录取得 10 项；《三国演义（原著）》“序言”取得 6,272 字符的 HTML，完整链路约 9.3 秒。这是单书单章的观测，不是性能基准。
- 文库已通过原本失败的请求解析，真实请求到达站点后返回 HTTP 403。离线契约验证通过不能替代站点放行后的在线阅读验证。
- 未验证 Android/iOS 真机、真实账号登录、HTML 自定义设置页/段评交互；`getfinds/find` 发现接口尚未接入。当前 HTML 能力范围为搜索、详情、目录、正文与共享登录字段/动作。

原文件离线探针：

```sh
SOURCE_WENKU_PATH=/absolute/wenku.json flutter test --no-pub tool/source_wenku_contract_probe_test.dart --reporter expanded
SOURCE_HTML_PATH=/absolute/光遇聚合.json flutter test --no-pub tool/source_html_contract_probe_test.dart --reporter expanded
```


## 回归验收

- 73 个书源相关测试文件逐文件使用独立 Flutter 进程执行；首次发现的列表空字符串契约回归、测试 binding 缺失和编辑页假时钟挂起均已修复后复验，未删除或跳过断言。
- 两个外部原文件离线探针分别通过；36 个修改/新增 Dart 文件格式检查与 `dart analyze` 均通过；`git diff --check` 通过。
- macOS JavaScriptCore 一次原生崩溃的堆栈落在 host callback 的 `Function.apply`；改为同步单参数直接调用，兼容套件连续 3 次各 13 项通过，运行时 4 项（含 100 次创建/销毁）通过。这支持该最小修复，但不等于证明所有原生偶发问题已根除。
- HTML 运行时 8 项通过，包括取消后队列恢复、远程分页及安全登录缓存删除。登录字段/会话另有 2 项回归通过。

- Web 条件编译探针（`SourceRuntimeScriptOwner` 创建/关闭）构建通过，产物输出到临时目录；这不是完整应用发布验证。Wasm 预检仍报告既有第三方依赖不兼容，当前通过的是 JavaScript Web 编译。

## 2026-10-02 在线复测

当前原文件搜索链路：光遇对两个查询均在搜索阶段报 `TypeError: undefined is not an object (evaluating books_data.length)`，未进入详情、目录或正文；文库搜索返回 HTTP 403。上述先前成功结果不能代表当前上游可用性。当前离线测试证明通用规则/桥接契约，真实站点恢复后仍需重新验收完整在线链路。

只读上游定位：按 APP 默认搜索参数直接请求 v1–v7 七条线路，7/7 为 HTTP 502（text/plain，16 bytes，非 JSON）；同服务 HTML/JSON 配置接口为 HTTP 200。源脚本捕获所有线路的 HTTP 错误后返回空对象，继而读取缺失的 data.length，因此二次 TypeError 掩盖了上游 502。远端新版仍有相同错误处理。通用传输层正常拒绝失败响应，不应添加站点特判或把失败转换为空成功。
