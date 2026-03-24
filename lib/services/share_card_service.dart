import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Renders a widget to an image and shares it.
class ShareCardService {
  /// Captures the widget behind [key] as a PNG and shares it.
  /// The [key] must be attached to a RepaintBoundary.
  static Future<void> shareCard(GlobalKey key, {String? text}) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/winkidoo_battle_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: text ?? 'Check out my Winkidoo battle! \u{1F48C}',
        ),
      );
    } catch (e) {
      debugPrint('ShareCardService.shareCard error: $e');
    }
  }
}
