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

  /// Presents a crop UI for the image at [sourcePath].
  ///
  /// When [lockSquare] is true the crop is locked to a 1:1 square (used for
  /// avatars); otherwise the crop is free-form (used for surprise / dare photos).
  ///
  /// Returns the cropped bytes. If the platform doesn't support cropping, or the
  /// user cancels the crop, returns [originalBytes] so the upload flow continues
  /// with the un-cropped image. (On web a fixed ratio is best-effort — the
  /// cropper plugin doesn't expose a hard ratio lock there.)
  static Future<Uint8List> cropOrOriginal({
    required BuildContext context,
    required String sourcePath,
    required Uint8List originalBytes,
    int compressQuality = 90,
    bool lockSquare = false,
  }) async {
    if (!_supported) return originalBytes;

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: compressQuality,
      aspectRatio:
          lockSquare ? const CropAspectRatio(ratioX: 1, ratioY: 1) : null,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: AppTheme.primary,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: AppTheme.primary,
          lockAspectRatio: lockSquare,
          initAspectRatio: lockSquare
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.original,
          // Hide the ratio chips when locked so users can't unlock it.
          hideBottomControls: lockSquare,
        ),
        IOSUiSettings(
          title: 'Crop',
          aspectRatioLockEnabled: lockSquare,
          resetAspectRatioEnabled: !lockSquare,
          aspectRatioPickerButtonHidden: lockSquare,
        ),
        WebUiSettings(context: context),
      ],
    );

    if (cropped == null) return originalBytes;
    return cropped.readAsBytes();
  }
}
