import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class IdCardItem {
  final String id;
  Uint8List originalBytes; // 原始图片字节
  Uint8List processedBytes; // 处理后的图片字节
  
  // 物理尺寸 (毫米) - 身份证标准: 85.6 x 54 mm
  double x; 
  double y;
  double width;
  double height;

  // 图像调整参数
  double brightness; // -100 到 100
  double contrast;   // 0.5 到 2.0
  double sharpness;  // 0.0 到 2.0

  IdCardItem({
    required this.originalBytes,
    required this.processedBytes,
    this.x = 20.0, // 默认左边距20mm
    this.y = 40.0, // 默认上边距40mm
    this.width = 85.6,
    this.height = 54.0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.sharpness = 0.0,
  }) : id = const Uuid().v4();
}
