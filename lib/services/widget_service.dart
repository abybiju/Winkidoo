import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const _appGroupId = 'group.com.winkidoo.app';
  static const _iOSWidgetName = 'WinkidooWidget';
  static const _androidWidgetName =
      'com.winkidoo.winkidoo.WinkidooWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Updates the home screen widget with current app state. Non-critical.
  static Future<void> update({
    required int streak,
    required int pendingSurprises,
    String prompt = '💝 Create a surprise for your partner today!',
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<int>('pending', pendingSurprises);
      await HomeWidget.saveWidgetData<String>('prompt', prompt);
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {}
  }
}
