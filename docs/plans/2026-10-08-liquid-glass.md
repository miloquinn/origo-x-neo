# 玻璃样式与液态材质实验

用户要求先保存当前工作并推送，再在「玻璃效果」开启时显示毛玻璃/液态玻璃选择。共享工作区基线 `43cfb4ee` 已提交并推送；本次不改发行版本或服务合同。

## 设置合同

- 旧 `ui_style_mode=glass/material3` 继续控制总开关；独立 `glass_style_mode=frosted/liquid` 保存材质。
- 缺失或未知材质值回退毛玻璃；总开关关闭不删除材质偏好。
- `ThemeNotifier` 同步共享配置，并将材质纳入 `UiStyleThemeExtension`，使现有页面即时更新。
- 开关下方条件展示选项，原生样式底部弹层进行二选一；尊重减少动画、小屏和大字号。

## 渲染合同

- 保留毛玻璃现有实现；首页/统计浮动导航、共享玻璃按钮和阅读控制栏使用同一个液态 renderer。
- shader 采样实时背景，圆角边缘向内折射，中心轻微放大，固定五次采样柔化。GPU 不保存整屏截图。
- 每次场景合成计算实际变换并更新 shader 局部坐标，使已有弹性变形与布局一致；更新 uniform 后创建新的原生滤镜。
- 轮廓高光按原 `OutlinedBorder` 路径绘制，内容保持清晰；已有 `blurBackground:false` 合同不叠加背景滤镜。
- 全宽顶部继续使用已有渐进高斯模糊，在液态样式降低强度；独立模态遮罩保留其语义，不把全屏遮罩做成凸透镜。
- 不支持 `ImageFilter.shader` 的后端/加载失败提供轻模糊+边缘高光。高对比模式提供更实的基底。总开关关闭不会保留液态滤镜。

能力依据：[Flutter fragment shaders](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)、[ImageFilter.shader](https://api.flutter.dev/flutter/dart-ui/ImageFilter/ImageFilter.shader.html)，以及当前 Flutter 3.44.7 的本地渲染/Impeller 源码。没有引入第三方玻璃包。

## 验证与交付

1. 存储迁移、选择记忆、设置显隐/选择、大字号及已有共享玻璃/导航/阅读 chrome 回归，各有状态的文件独立进程运行。
2. 全仓 Flutter analyze，真实 iOS Simulator Impeller 对比预览，确认 shader 已加载且背景可折射。
3. 本地 direct 渠道 release 构建、签名检查、SloanePro 身份匹配、覆盖安装与启动回读，保留数据。
4. 保存验收记录，提交并推送功能。物理手势、滚动帧率和用户视觉接受不由单元测试或安装成功替代。
