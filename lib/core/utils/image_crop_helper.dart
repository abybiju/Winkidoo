import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../theme/app_theme.dart';

/// Shared free-form image cropping used by every photo-upload flow
/// (surprise photo, custom judge avatar, profile avatar, dare photo).
///
/// `image_cropper` only supports Android, iOS, and Web. On macOS / desktop the
/// plugin is unimplemented, so [cropOrOriginal] silently returns the original
/// bytes there instead of throwing.
class ImageCropHelper {
  const ImageCropHelper._();

  static bool get _supported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Presents a free-form crop UI for the image at [sourcePath].
  ///
  /// Returns the cropped bytes. If the platform doesn't support cropping, or the
  /// user cancels the crop, returns [originalBytes] so the upload flow continues
  /// with the un-cropped image.
  static Future<Uint8List> cropOrOriginal({
    required BuildContext context,
    required String sourcePath,
    required Uint8List originalBytes,
    int compressQuality = 90,
  }) async {
    if (!_supported) return originalBytes;

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: compressQuality,
      // No aspectRatio + unlocked controls => free-form crop.
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: AppTheme.primary,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: AppTheme.primary,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
        WebUiSettings(context: context),
      ],
    );

    if (cropped == null) return originalBytes;
    return cropped.readAsBytes();
  }
}
