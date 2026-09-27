# 单入口账号卡

用户要求：未拥有开卷仅显示开卷；已有开卷显示开通探元；探元只显示自身权益并注明包含开卷。官网免费开卷保持直接进入探元。

复用既有两个购买页与主题色，删除组合卡的双入口、金色渐变、装饰纹理和嵌套会员面板；其它独立账号卡不受影响。

Flutter 实际渲染：

- [未开通](account-read.png)
- [已有开卷](account-upgrade.png)
- [已有探元](account-explore.png)
- [深色及紫色强调色](account-dark.png)
- [320px / 1.6 倍字号](account-large.png)

主标题与会员标题共享横坐标；按钮不并列，状态变化不更改账号权益。新版尚未包含在已发布的 260927002 / 260927003 安装包中。

验证：store_account_entry_test 8 项、settings_page_test 18 项、settings_premium_access_test 2 项通过；相关四文件 Flutter analyze 无问题。
