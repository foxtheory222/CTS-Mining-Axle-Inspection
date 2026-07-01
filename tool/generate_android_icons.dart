import 'dart:io';

import 'package:image/image.dart' as image;

const String sourceLogoPath = 'assets/logo/cts_logo.png';
const String previewIconPath = 'assets/logo/cts_app_icon.png';

const Map<String, int> mipmapSizes = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

void main() {
  final sourceBytes = File(sourceLogoPath).readAsBytesSync();
  final source = image.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('Unable to decode $sourceLogoPath');
  }

  final mark = _cropCtsMark(source);
  final icon = _composeIcon(mark, 1024);
  File(previewIconPath).writeAsBytesSync(image.encodePng(icon));

  for (final entry in mipmapSizes.entries) {
    final resized = image.copyResize(
      icon,
      width: entry.value,
      height: entry.value,
      interpolation: image.Interpolation.cubic,
    );
    File('android/app/src/main/res/${entry.key}/ic_launcher.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image.encodePng(resized));
  }
}

image.Image _cropCtsMark(image.Image source) {
  final searchWidth = (source.width * 0.24).round();
  var minX = source.width;
  var minY = source.height;
  var maxX = 0;
  var maxY = 0;

  for (var y = 0; y < source.height; y += 1) {
    for (var x = 0; x < searchWidth; x += 1) {
      final pixel = source.getPixel(x, y);
      final alpha = pixel.a.toInt();
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();
      final isWhite = red > 238 && green > 238 && blue > 238;
      if (alpha > 20 && !isWhite) {
        minX = x < minX ? x : minX;
        minY = y < minY ? y : minY;
        maxX = x > maxX ? x : maxX;
        maxY = y > maxY ? y : maxY;
      }
    }
  }

  if (minX >= maxX || minY >= maxY) {
    throw StateError('Unable to find CTS mark in $sourceLogoPath');
  }

  final width = maxX - minX + 1;
  final height = maxY - minY + 1;
  final pad = (width > height ? width : height) ~/ 5;
  final cropX = (minX - pad).clamp(0, source.width - 1);
  final cropY = (minY - pad).clamp(0, source.height - 1);
  final cropRight = (maxX + pad ~/ 3).clamp(0, source.width - 1);
  final cropBottom = (maxY + pad).clamp(0, source.height - 1);

  return image.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: cropRight - cropX + 1,
    height: cropBottom - cropY + 1,
  );
}

image.Image _composeIcon(image.Image mark, int size) {
  final canvas = image.Image(width: size, height: size, numChannels: 4);
  image.fill(canvas, color: image.ColorRgba8(255, 255, 255, 255));

  final markMaxSize = (size * 0.74).round();
  final resized = mark.width >= mark.height
      ? image.copyResize(
          mark,
          width: markMaxSize,
          interpolation: image.Interpolation.cubic,
        )
      : image.copyResize(
          mark,
          height: markMaxSize,
          interpolation: image.Interpolation.cubic,
        );

  image.compositeImage(
    canvas,
    resized,
    dstX: ((size - resized.width) / 2).round(),
    dstY: ((size - resized.height) / 2).round(),
  );
  return canvas;
}
