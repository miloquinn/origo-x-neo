# 2026-10-10 用户书源登录兼容与样本整理

这是当日诊断与验证记录。当前维护入口为[书源架构](../../lib/book_sources/README.md)，不应把这里的网络状态作为今后的站点可用性结论。

## 输入与根因

用户提交 `/Users/xiaoyuan/Documents/QQ/shareBookSource (1).json`，包含 UAA 四合一、番茄四合一（知秋段评）、爱丽丝书屋和少年梦。原文件保持不变。三个源的 `loginUi` 混用单引号，严格 JSON 解析曾把异常吞为无字段；表单重排也把必要的作者、反馈群、口令等字段折进额外设置。字段名包含的空格同时是脚本读取 `result` 的键，不能为显示方便改变其身份。

另外，爱丽丝使用空 `type` 的 data URI 传递书籍和章节 ID，旧请求逻辑误把它当网络 URL。其元数据规则混合 HTML 属性选择器与 JSON 字段，属性值内的冒号曾被误认为 JSONPath slice，阻止后面的 JSON fallback。裸 JSON data payload 的首逗号和嵌套逗号也曾被误当请求选项分隔符。

## 通用修复

- 有限的声明数据解码器保留严格 JSON 路径，兼容混合引号、简单裸键、注释和尾逗号，不执行声明中的表达式。
- 表单保留源声明的顺序、分组和按钮宽度比例；动作后的已保存值立即刷新，旧的 trimmed-key 会话值仍能恢复，明确清除恢复默认值。显示标签与精确字段键分开。
- 脚本生成表单的会话写入也持久化；登录继续使用现有独立安全会话和网络重放机制。
- data 字节/ID 在本地按既有 hex 协议解析，空类型可用；未指定类型的 HTTP(S) wrapper 保留网络行为。请求选项采用共用边界解析。缓存规则版本从 6 升至 7。
- 混合规则中的 HTML 属性谓词不会误判为 JSON slice；显式 JSONPath 错误和真实 slice/union 行为继续保留。

没有按名称、域名添加分支，没有修改原书源脚本或引入依赖。

## 验证与边界

16 个回归文件以独立 Flutter 进程运行，177 项通过，覆盖声明解析、动态表单、动作后刷新、会话重建、网络请求、data 完整链路、JSON/HTML 混合规则、缓存与模块所有权。定向静态分析、格式和 diff 检查通过。失败基线、最终日志和范围计划在 `build/source-compatibility-20261010/`。一次并行验证期间出现 GBK 表初始化类型异常，单用例与完整请求文件在独立进程均通过；没有为这次未能单独复现的运行器现象改变产品编码逻辑。

改动文件包括 `source_engine/source_json.dart`、`source_login_ui.dart`、`source_runtime_login.dart`、`source_request_template.dart`、`source_runtime_request_helpers.dart`、`rules/source_rule_json.dart`、`protocol/reading_source/reading_source_backend.dart`、`pages/book_sources/source_login_page.dart`，以及五个对应回归文件、当前架构说明和 `tool/benchmark_real_source_import.dart`。具体入口见当前维护指南。

对原始四源分别执行搜索→详情→目录→正文，使用合成 HTTP 响应和测试会话，4/4 通过。加载到的表单字段数依次为 31、55、20、18；逐源执行原始“获取Token”动作并验证 session/source cache 写入及重建，2 项外部样本探针通过。外部原始样本不提交进仓库，诊断不输出真实 Token。日志在 `build/source-diagnostics/zhiqiu_chain_fixture_probe.log` 和 `zhiqiu_login_fixture_probe.log`。

空会话在线搜索没有完成真实账号验收：三源返回 401；UAA 在缺少缓存 androidId 时，原始脚本对缺省第三参数 `_` 的 `.java` 解引用失败。该源的“获取Token”动作传入 `this` 并保存 androidId；动作探针已证明初始化路径。通用函数调用绑定保持原参数语义，不为任意 jsLib 函数擅自填参数。真实用户应先按书源要求填写表单并获取 Token。

四源的共享服务阅读链通过离线验证，不代表所有额外功能均已支持。JavaImporter 中的部分 Hutool/OkHttp 类、System.nanoTime、Android 视频播放器及段评 SVG 图片路径仍超出现有宿主契约；官方直连、增强段评和真实 Token 发行/过期尚未验收。

递归导入整理后的样本库通过：20 个书源 JSON、10089 个合法候选记录，另有 16 个原样保留的格式错误；替换规则目录排除。这里的导入结果只证明静态导入，不代表在线可读。

## 资源目录迁移

`/Users/xiaoyuan/work/书资源` 已按收件箱、小说源、漫画源、本地书籍、替换规则、历史文档和重复归档分类，另有可搜索 CSV 索引、迁移映射及标准库索引/校验工具。48 个旧文件全部能按映射找到，字节哈希均相同；一组完全相同的重复副本保留在重复归档。新 QQ 原件按日期收件并与外部原件校验相同。静态索引包含 10105 条源记录、273 条替换规则和 24 本书，状态默认未验证，不写入账号或登录脚本。

完整备份为同级 `书资源-完整备份-20261010-145819.tar.gz`，SHA-256：`48ce9c629bf9e18bf9d81c721fe1c79350fd18f2cf469427360ffd3d3a93dd59`。迁移工具同时核对备份成员和当前文件，报告无错误。目录 README、index 和 manifest 是今后查找与复核的入口；历史交接中的敏感原文保持原件，仅留在历史资料，不复制到索引。

## 设备交付

本次改动纳入共享 checkout 的统一 SloanePro 安装，由主题任务持有唯一安装所有权，避免其他任务的旧快照覆盖最新应用。`build/device-ios/coordination.json` 记录本次最终源码哈希，签名构建收据需逐项匹配这些哈希。构建、原地安装、启动与真实登录/阅读 UI 验收分别记录；真实账号验收不会由离线探针替代。
