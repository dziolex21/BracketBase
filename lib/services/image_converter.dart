import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart'; // for compute

/// Processes an image (PNG/JPG) in a background isolate.
///
/// 1. Decodes the bytes (works for both PNG and JPG).
/// 2. **Forcibly resizes to 150x150 (may stretch/squash the image).**
/// 3. Encodes to JPG format with 85% quality.
///
/// This function should be called using `compute()` (see example).
Uint8List processImage(Uint8List imageBytes) {
  // 1. Decode the image
  img.Image? originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    throw Exception('Could not decode image data.');
  }

  // 2. Resize to 150x150 (without cropping)
  //    This will squash the image if the aspect ratio is not 1:1
  img.Image resizedImage = img.copyResize( // <--- CHANGE IS HERE
    originalImage,
    width: 400,
    height: 400,
    interpolation: img.Interpolation.linear, // Good quality for downscaling
  );

  // 3. Encode to JPG
  Uint8List jpgBytes = img.encodeJpg(resizedImage, quality: 85);

  return jpgBytes;
}

/// A helper class to call `processImage` from your UI.
class ImageConverter {
  /// Processes an image asynchronously without blocking the UI.
  ///
  /// Takes a [Uint8List] (bytes) of the original file.
  /// Returns a [Uint8List] of the processed 150x150 JPG.
  static Future<Uint8List> convert(Uint8List originalBytes) {
    // compute() runs the function in a separate isolate
    return compute(processImage, originalBytes);
  }
}