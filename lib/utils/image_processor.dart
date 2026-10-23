import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class ImageProcessor {
  // 在后台线程处理图像，防止UI卡顿
  static Future<Uint8List> processImage(
    Uint8List bytes,
    double brightness,
    double contrast,
    double sharpness,
  ) async {
    return await compute(_processInBackground, {
      'bytes': bytes,
      'brightness': brightness,
      'contrast': contrast,
      'sharpness': sharpness,
    });
  }

  static Uint8List _processInBackground(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final brightness = params['brightness'] as double;
    final contrast = params['contrast'] as double;
    final sharpness = params['sharpness'] as double;

    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // 用非可空变量承接，避免后续类型检查报错
    img.Image image = decoded;

    // 调整亮度和对比度
    if (brightness != 0.0 || contrast != 1.0) {
      image = img.adjustColor(
        image,
        brightness: (brightness / 100).clamp(-1.0, 1.0),
        contrast: contrast.clamp(0.1, 3.0),
      ) ?? image;
    }

    // 锐化：image 4.x 中 sharpen/copySharpen 函数已移除，暂时跳过
    // 如需锐化功能，可添加 dependency: image_filters: ^1.2.0
    // import 'package:image_filters/image_filters.dart' show sharpen;
    // if (sharpness > 0.0) {
    //   image = sharpen(image, amount: sharpness.clamp(0.0, 2.0));
    // }

    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }
}
