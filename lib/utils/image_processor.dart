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

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // 调整亮度和对比度
    if (brightness != 0.0 || contrast != 1.0) {
      image = img.adjustColor(
        image,
        brightness: (brightness / 100).clamp(-1.0, 1.0),
        contrast: contrast.clamp(0.1, 3.0),
      );
    }

    // 锐化
    if (sharpness > 0.0) {
      image = img.sharpen(image, amount: sharpness.clamp(0.0, 2.0));
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }
}
