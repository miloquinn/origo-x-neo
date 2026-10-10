# 服务名称、图标与许可页

## 当前显示与所有权

AI 配置和云端 TTS 配置使用服务名称与 Origo X 的中性图标。用户于
2026-10-10 确认未取得品牌方书面 Logo 授权，并选择先使用中性图标。
`AiProviderLogo` 因此复用 `AppSkinIcon` 的 `network` 槽位，不读取第三方
Logo 图片；`CloudTtsProviderLogo` 继续复用同一入口。原有名称、模型、
接口和协议配置均保留。

`AIModelPreset.logoAsset` 与 `logoAssetForSettings` 的原路径目前仅作为
服务身份匹配的兼容标识，不表示允许展示相应图片。不要因为这些字段
仍存在，就绕过共享图标组件直接 `Image.asset`。旧 PNG 暂留在包中并保留
版权许可；它们不是当前 UI 的显示资产。

## 版权与品牌权利

旧素材来自 Lobe Icons 提交
`c385b2b8d1f9e19aa86e628d4e23c91ee1111a47`。完整 MIT 原文与 LobeHub
版权声明在 `assets/ai_providers/LICENSE-MIT.txt`；来源和转换记录在同目录
`NOTICE.md`。库的版权许可不等于第三方商标使用许可，免责声明也不能
代替品牌要求的同意。

`assets/ai_providers/BRAND-NOTICE.txt` 单独记录中英双语服务名称归属、
无合作/赞助/认可关系、当前中性图标策略，以及恢复品牌标识的条件。
`registerProviderAssetLicenses` 被启动入口 `registerAppSkinLicenses` 调用，
幂等注册两条离线通知到 `LicenseRegistry`；无需网络、密钥或账户。

## 官方来源核对记录（2026-10-10）

此表记录公开规则与资产身份核对，未取得授权书。下载入口、官方产品
页面或开源模型许可本身都不能作为第三方 Logo 使用授权。未找到公开
规则也不表示品牌放弃权利。

| 服务 | 官方依据 | 旧资源问题与恢复条件 |
| --- | --- | --- |
| OpenAI | [品牌规范](https://openai.com/brand/) | 要求官方原件、禁止添加颜色/修改，Blossom 需留白且仅用于直接相关服务。恢复前获取当前官方原件并遵循使用条款，不把 Lobe 转换件当作已获批准的原件。 |
| Claude / Anthropic | [官方 2026 报告](https://resources.anthropic.com/hubfs/The%202026%20State%20of%20AI%20Agents%20Report.pdf) | 官方可见橙色 sunburst；这只能核对形态，未确认公开第三方 Logo 授权。恢复前取得资产和适用规则。 |
| Google Gemini | [官方标识更新](https://blog.google/company-news/inside-google/company-announcements/gradient-g-logo-design/)、[品牌中心](https://about.google/brand-resource-center/guidance/)、[API 条款](https://developers.google.com/terms) | 官方 spark 更新为四色渐变；产品图标需按品牌流程使用。API 条款可能提供受限制的许可，不能推定覆盖所有自定义连接。恢复前确认许可适用范围并取得官方资产，禁止主题染色。 |
| DeepSeek | [官方条款](https://cdn.deepseek.com/policies/en-US/deepseek-terms-of-use.html) 第 6.2 节 | 未经许可不得展示或使用其 Logo/品牌特征；先取得适用许可。 |
| 通义千问 / Qwen | [官方条款](https://qwen.ai/termsservice) 第 V.1 节 | QWEN/TONGYI 与图标不得未经授权复制、修改、使用或发布；不能按截图自行改色或重绘。 |
| 智谱 / Z.ai | [Z.ai 条款](https://chat.z.ai/legal-agreement/terms-of-service) 第 V.2 节 | `zhipu.png` 实际是 Z.ai 的 `Z_`，不是国内 BigModel 标志。恢复前先明确国内智谱还是国际 Z.ai 服务身份，再核对对应权利人的资产与书面许可。 |
| MiniMax | [官方用户协议](https://agent.minimaxi.com/doc/zh/terms-of-service.html) 知识产权部分 | 商标、标识及 Logo 需事先书面许可。该协议用于其 Agent 产品；API/App 的具体授权范围仍需另行确认。 |
| Kimi / Moonshot AI | [品牌手册](https://www.kimi.com/resources/kimi-brand)、[Logo 条款](https://www.kimi.com/zh-cn/policies/logo-usage-terms) | `moonshot.png` 是旧 Moonshot 标识，UI 名称是 Kimi。公开授权范围限媒体、新闻、非商业展示，禁止变色/变形；商业 App 恢复前需取得对应许可和当前官方 Kimi 资产。 |
| Groq | [商标政策](https://groq.com/trademark-policy) | 明确规定 UI 使用 Logo 要许可；允许必要、真实、不暗示关联的文字指称并要求归属声明。本 App 已单独补充 Groq 归属及无关联声明。 |
| 硅基流动 / SiliconFlow | [品牌规范](https://cloud-rd.siliconflow.cn/brand)、[平台条款](https://docs.siliconflow.cn/docs/legals/terms-of-service) | 旧资源为 `siliconcloud-color`，应核对当前 SiliconFlow 官方资源包。标准色为紫 `#6E29F6`、白、黑；下载按钮不等于无限授权，恢复前确认包内规范与适用许可。 |
| 豆包 / Doubao | [官方用户协议](https://www.doubao.com/legal/terms) 第 8.5 节 | 未经事先书面同意不得展示/使用 Logo；云端 TTS 的具体许可应向相应服务权利人确认。 |
| Xiaomi MiMo | [官方 MiMo-Code 仓库](https://github.com/XiaomiMiMo/MiMo-Code)、[模型许可](https://github.com/XiaomiMiMo/MiMo/blob/main/LICENSE) | 仓库注明 Logo 受 MiMo Trademark Policy 约束，公开政策入口未确认；Apache-2.0 第 6 节不授予商标权。恢复前获取政策及所需许可。 |

旧资源的主题 `onSurface` 染色会把黑白标识变成任意主题色，不能保留。
当前通过停止品牌图片展示同时消除了任意染色和三处身份错配。以后如
恢复 Logo，需要逐家确认允许的黑白/全彩变体、比例、留白、背景、应用
用途和同意记录；不要统一开启一个“MIT 所以允许”的开关。

## App 内入口与共享 UI

- 设置中的开源与字体许可：`OpenSourceLicensesPage`，保留项目、历史
  MIT、字体、艺术素材与所有 Flutter/Dart 依赖。
- 主题中的“素材与开源致谢”：同一页面，传入 `title` 和
  `prioritizeAssets: true`，优先呈现素材条目。
- 列表和详情复用 `FloatingSubpageScaffold`、`GlassSurface`、
  `AppSkinIcon`；依赖搜索使用 `PillSearchField`，主题入口使用
  `GlassTextButton`。由共享材质解析处理玻璃/无玻璃与明暗模式，
  不再导航到默认 `LicensePage`。
- 依赖目录一次读取完整 `LicenseRegistry`，按 package 名分组；多包
  共享的通知在每个包中保留，多条许可不合并丢失。详情保留段落、缩进、
  居中标题与可选择文本，许可全文随包离线可读。

## 回归入口与交付边界

`test/provider_asset_licenses_test.dart` 验证完整 MIT、独立品牌声明、幂等
启动注册与皮肤许可兼容；`test/ai_provider_logo_test.dart` 验证两种明暗
模式下不加载第三方品牌图片；`test/open_source_licenses_page_test.dart`
验证离线正文、多包多通知、搜索和段落格式；
`test/open_source_licenses_rendering_test.dart` 验证玻璃/无玻璃、明暗、
320px/200% 字号与生产组件截图；`test/app_theme_page_test.dart` 验证主题
设置及致谢入口。每个 stateful widget 套件独立运行。

测试/截图不代表品牌授权，也不等于 SloanePro 真机 UI 验收。合并安装
由 `build/device-ios/coordination.json` 指定的唯一安装负责人执行，避免
用旧快照覆盖其他聊天正在完成的功能。
