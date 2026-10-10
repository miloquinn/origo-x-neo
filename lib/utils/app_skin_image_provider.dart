// 文件说明：按平台导出统一的皮肤图片提供器。

export 'app_skin_image_provider_io.dart'
    if (dart.library.html) 'app_skin_image_provider_web.dart';
