import 'package:go_router/go_router.dart';

class NotificationRouter {
  static void navigate(GoRouter router, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'season_launch':
        router.go('/shell/create');
        return;
      case 'dare':
      case 'dare_partner_responded':
      case 'dare_result':
        router.go('/shell/home');
        return;
      case 'mini_game':
      case 'mini_game_partner_responded':
      case 'mini_game_result':
        router.go('/shell/home');
        return;
      case 'campaign':
        final campaignId = data['campaign_id'] as String?;
        if (campaignId != null) {
          router.go('/shell/campaign/$campaignId');
        } else {
          router.go('/shell/campaigns');
        }
        return;
      case 'custom_judge_ready':
        router.go('/shell/my-judges');
        return;
      case 'friend_request':
      case 'friend_accepted':
        router.push('/shell/chat/add-friends');
        return;
      case 'chat_join_request':
      case 'chat_join_approved':
      case 'scene_started':
      case 'scene_act_ended':
        final roomId = data['room_id'] as String?;
        if (roomId != null && roomId.isNotEmpty) {
          router.push('/shell/chat/$roomId');
        }
        return;
    }
    final surpriseId = data['surprise_id'] as String?;
    if (surpriseId == null || surpriseId.isEmpty) return;
    router.go('/shell/battle/$surpriseId');
  }
}
