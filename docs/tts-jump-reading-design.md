# 听书跳读与连续播放

这是听书展示、跳读与连续播放的当前维护入口。早期跳读验证见 [2026-10-03 记录](reviews/2026-10-03-tts-jump-reading-validation.md)，2026-10-09 增加阅读排版共用合同；封面与响应式布局见 [2026-10-10 验证](reviews/2026-10-10-aloud-layout-validation.md)。

## 交互合同

- 共用 ReaderAloudController；全文位置用章节 ID 与原文字偏移，点击始终归到句首。
- 专门听书页默认正文；手机顶部显示小封面、书名、作者和当前章节，保留大封面切换。平板/电脑同时显示左侧封面及控制、右侧正文。正文单击从句首播放，暂停时点击也播放；点击当前句重听。浏览正文不改变播放位置，暂停自动跟随，并提供回到正在朗读。
- 阅读页新增「点句跳读」，默认关闭，持久化。只在当前书的听书会话启用；打开后正文短点优先跳读，滑动翻页、长按选字与批注继续工作。空白不吸附到正文。
- 快速连续跳读只保留最新目标；等待音频有准备状态，不伪造已播放的句子进度。定时停止不因跳读重置。
- 「手动翻页改变朗读位置」保持独立设置、默认关闭。其原有保存值不迁移。

## 封面与响应式播放器

- `lib/core/reader/reader_aloud_controller.dart`：可选 `ReaderAloudMetadataSource` 提供不可变 `ReaderAloudBookMetadata`。它包含作者、本地封面路径、在线 URI 与防盗链请求头，不参与声音合成。`CallbackReaderAloudSource` 携带元数据；同书 `rebindSource` 更新展示快照，保留播放位置、暂停状态和定时器。不要把封面只作为首次打开页面的临时参数。
- `native_reader_controls.dart` 从运行时 `_activeBook` 读取封面；`BookCoverReference.fromBook` 共用书架的解析，TXT、EPUB 等本地格式优先 `coverImagePath`，下载书同时保留 `sourceBookJson.coverUrl/coverHeaders`，相对地址按 `sourceJson.apiBaseUrl` 解析。`book_source_reader_settings.dart` 使用已规范化的 `BookSourceBook.coverUrl/coverHeaders`。导入提取与封面持久化仍由现有书籍服务所有。
- `lib/models/book_cover_reference.dart` 与 `lib/widgets/book_cover_image.dart` 是书架网格、列表和听书封面的共用合同：本地图片成功后不请求远端，本地不存在或解码失败再用 `SourceCoverImage` 的请求头、缓存与错误处理，远端也失败才回到调用方默认封面。`reader_aloud_cover.dart` 只负责元数据适配和 `GeneratedBookCover`。书架继续保留原来的裁剪、解码尺寸和占位策略；Web 不读取宿主文件系统，直接使用远端或默认封面。
- 只接受带主机的 HTTP(S) 封面地址；协议相对地址按有效书源基地址解析，损坏元数据或不支持的协议回到默认封面。听书封面根据实际显示宽度和设备像素密度限制解码尺寸，小封面不解码整张高分辨率图片。
- `lib/widgets/reader_aloud_panel.dart`：手机默认正文，小封面放在标题左侧；顶部只保留关闭、封面/正文与声音设置。正文占主要高度，底部保留前后句和播放暂停，目录/倍速/定时常用入口同排；音量、前后章和结束听书进入「更多」。底部控制菜单仍保留已有完整入口和滚动能力。
- 可用宽度至少 700，或至少 500 且宽于高度，采用双栏；安全区先扣除。左侧封面下方固定主控制，右侧正文独立滚动。短横屏用小封面书籍信息吸收高度限制，不挤压主控制。内容最大宽度 1200，手机最大 560。
- `lib/widgets/reader_aloud_transcript.dart` 的 `onBrowse` 只由用户滚动通知触发；手机自动收起扩展控制，通过底部展开按钮或控制区背景恢复。播放暂停和前后句始终可用，正文浏览不改变朗读位置。自动播放跟随不会收起控制，大屏控制保持展开。首句从正文顶部显示，之后活动句跟随到视口约三分之一处。
- 手机控制使用同一套主播放控件；320ms 缓入缓出同时驱动扩展按钮/进度的透明度、下滑和高度，以及播放键的尺寸与排列。展开/收起按钮常驻主播放行，箭头同步旋转，快速再次点击从当前帧反向；隐藏控件退出触摸和无障碍语义。系统减少动态效果时直接改变布局，正文跟随改为即时定位。封面/正文切换不启动新会话，不改变语音、书籍位置或睡眠定时。
- 回到朗读使用共享 `GlassTextButton` 胶囊，悬浮于正文区域末端侧与底边各 12px，点击区至少 44px。正文滚动视口在按钮上方避让 8px；避让高度跟随当前界面字体与文字缩放测量，整个可读区域及末句不经过按钮后面。透明避让带不绘制整行底栏；恢复跟随后收回按钮与避让空间。

回归入口：`test/book_cover_image_test.dart` 验证存储元数据解析、不可变请求头、本地成功不加载远端、本地失效回退远端；`test/reader_aloud_cover_test.dart` 验证真实本地 PNG 解码、TXT/EPUB 共用合同、在线 URI/请求头、失败回退及同书元数据刷新；`test/native_reader_aloud_typography_test.dart` 从实际 TXT/EPUB 阅读页进入听书，验证下载书的远端封面回退；`test/reader_aloud_panel_test.dart` 验证手机默认正文、封面切换保留会话、手动收起/恢复的中间动画帧、快速反向、自动跟随、减少动态效果、目录、两种入口、音量提交、多种视口安全区及中英日文 2 倍大字。`test/reader_aloud_transcript_floating_test.dart` 验证悬浮胶囊、文字缩放后的视口避让、末句可见与点读命中及回到朗读；`tool/preview_reader_aloud_layout.dart` 使用生产播放器和真实本地图片，渲染手机、窄屏、横屏、平板与深色大字场景；模拟渲染不代表真机触摸或音频听感验收。

## 正文排版

朗读播放器的正文沿用当前书籍的阅读排版；按钮、标题和设置仍使用应用界面字体。不要用整个 APP 的 ThemeData 替换阅读字体，也不要用单一字体覆盖书内混合字体。

- `lib/core/reader/reader_aloud_controller.dart`：`ReaderAloudTextSource` 是可选展示合同，保存阅读 `TextStyle` 和书内字体保留选择。`ReaderAloudChapter.buildTextSpan` 描述该章精确文字版本的样式分段，不参与音频合成或改变原文偏移。
- `lib/pages/reader/native/native_reader_controls.dart`：取 `_readerTextStyle` 和 `_preserveDocumentFont`，读取章节时通过 `_loadIndexedChapter` 共用延迟加载、字体注册与替换准备，捕获文字及不可变 blocks。`native_reader_chapter.dart` 的正文和朗读均委托 `_styledSpanForNativeTextRange`，使用原有字体、fallback、变量字重、字号比例和粗斜体规则。
- `lib/pages/reader/book_source/book_source_reader_settings.dart`：书源朗读提供 `_bodyTextStyle`。书源无 EPUB 分段字体，不另写书籍字体推断。
- 两个阅读器每次打开播放器刷新展示 source，保留同一本书的 controller、播放位置和休眠状态。关闭原阅读页后，当前章的样式 callback 只读取已捕获的文本与 blocks，不访问已销毁的 State 或卸载章节。
- `lib/widgets/reader_aloud_transcript.dart`：只对活动句设置高亮颜色；保留阅读字体、字号、行距、字距和字重。正文 `Text.rich` 及 base style 显式 `inherit:false`，即使 family 为 null 也不继承应用装饰字体。加载提示等界面文本继续使用应用主题。

EPUB 仅“书籍内置”保留书内字体；系统与自定义选择按已有 `ReaderFontProfile.preservesParsedFontFor` 规则覆盖。Kindle 的默认与显式字体同样沿用该规则。缺失字体或缺字沿用阅读器回退，不能保证每本书的所有字形均由嵌入字体提供。

回归入口：`test/reader_aloud_typography_test.dart` 验证活动/非活动句、fallback、变量字重、混合字体和应用字体隔离；`test/native_reader_aloud_typography_test.dart` 从合成 EPUB 的真实阅读页进入播放器，验证书内/系统/自定义字体、远章节和原阅读页关闭后的快照；原有 `reader_aloud_panel_test.dart`、`reader_aloud_controller_test.dart`、`reader_font_profile_test.dart`、`native_reader_epub_chapter_transition_test.dart` 保留控制、会话与字体优先级回归。状态型 Widget 套件分进程运行。

## 设置入口

- 专门播放器的底部提供目录、倍速与定时；顶部打开完整听书设置。音量、前后章、结束听书统一放入「更多」，音量滑动预览保持本地状态，释放后才提交到当前系统或云端引擎。
- 完整设置按播放方式、声音和定时组织；听书展示方式为互斥选项，点句跳读和翻页跟随是两个独立开关。云端 API 参数仍由云端配置页维护。
- 简易听书控制菜单保留点句跳读和全部既有操作，可滚动；全屏播放器不复制这份设置菜单。窄屏、大字体和中英日文保持所有必要入口可达。

## 云端语音配置

- `lib/pages/settings/cloud_tts_settings_page.dart` 是应用设置与听书播放器共用的配置入口。主页面直接列出豆包、MiniMax、OpenAI、小米 MiMo 预设，以及已有的命名语音；点预设直接新建，点已保存语音直接编辑，当前配置显示选中标记。添加兼容服务直接进入自定义编辑，不再多跳一层服务列表。
- 编辑页优先展示语音模型、音色、API Key 和试听。模型与音频格式共用 `PillDropdown`，音色在 `GlassDialog` 中通过 `PillSearchField` 搜索；输入框共用 `PillInputSurface`，试听与保存共用 `GlassTextButton`。材质由共享玻璃层适配玻璃、无玻璃及明暗主题，不在页面内另写下拉材质。
- 配置名称、地址、自定义模型和音色 ID、音频格式、失败回退及密钥移除位于高级设置。收起高级区仍参与表单校验，失败时展开内联错误；自定义模型和音色输入即时更新上方选择器，不用预设值覆盖用户输入。
- `lib/widgets/cloud_tts_provider_logo.dart` 复用 AI 配置的中性服务图标，由 `AppSkinIcon` 的 `network` 槽位适配皮肤。未取得品牌方书面授权时不展示第三方 Logo；旧素材版权和品牌核对见 [服务素材与许可](provider-brand-assets.md)。
- 沿用现有 profile、密钥与试听合同：空白密钥保留已保存值，移除仅在保存时执行，退出编辑不会清除；不同配置的密钥独立，删除单个配置不影响其他语音。试听暂停听书，使用编辑中的参数与当前语速，停止或退出后旧请求不再发声。本轮不改变服务端协议、模型目录及播放引擎。

回归入口：`test/cloud_tts_settings_page_test.dart` 覆盖预设直达、自定义保存、选择器同步、折叠校验、命名语音和密钥隔离、保存失败重试、搜索音色、小屏键盘下保存及玻璃/无玻璃明暗场景；`test/reader_aloud_cloud_service_test.dart` 保留真实请求合同、配置迁移、试听取消与播放隔离回归。图形测试使用生产 Widget 渲染，不能代替真实服务音频与真机触摸验收。

## 云端边界

- 当前引擎只返回音频字节，没有真实句时间戳。保留句级高亮，不用字数比例冒充大段语音对齐。
- 当前阶段扩大有界前瞻缓冲，减少逐句播放器初始化，保证首句尽快启动；预取失败只在该句轮到播放时报告。
- 停止、暂停、跳读、切音色或语速后旧任务不得发声。请求与缓存有界，优先用户最新目标。
- 将来取得准确句时间信息后，可自然段批量合成并按句时间 seek，不绑定屏幕分页。

## 验收

- 本地文本与书源共用点击坐标到原文偏移；生成缩进、空行、跨页句子不破坏定位。
- 跳读句首、暂停跳读、快速跳读、跨章、停止后旧请求完成、定时停止有回归。
- 正文浏览与回到朗读、两种听书展示、设置持久化有组件回归。
- 云端预取比原来提前一句更充分，有界并发，取消后不播放，错误延后展示。
- 测试与静态检查通过；云端真实音频间隔和设备触摸手感需实机验证，不能以模拟测试宣称无缝。
