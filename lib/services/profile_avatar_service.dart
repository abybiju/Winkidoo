import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

enum ProfileAvatarMode { upload, preset, none }

class UserAvatarProfile {
  const UserAvatarProfile({
    required this.userId,
    required this.avatarMode,
    this.avatarAssetPath,
    this.avatarStoragePath,
    this.avatarUrl,
  });

  final String userId;
  final ProfileAvatarMode avatarMode;
  final String? avatarAssetPath;
  final String? avatarStoragePath;
  final String? avatarUrl;

  static const empty = UserAvatarProfile(
    userId: '',
    avatarMode: ProfileAvatarMode.none,
  );

  factory UserAvatarProfile.fromJson(Map<String, dynamic> json) {
    final modeValue = (json['avatar_mode'] as String? ?? 'none').toLowerCase();
    final mode = switch (modeValue) {
      'upload' => ProfileAvatarMode.upload,
      'preset' => ProfileAvatarMode.preset,
      _ => ProfileAvatarMode.none,
    };
    return UserAvatarProfile(
      userId: (json['user_id'] as String?) ?? '',
      avatarMode: mode,
      avatarAssetPath: json['avatar_asset_path'] as String?,
      avatarStoragePath: json['avatar_storage_path'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'avatar_mode': avatarMode.name,
        'avatar_asset_path': avatarAssetPath,
        'avatar_storage_path': avatarStoragePath,
        'avatar_url': avatarUrl,
      };
}

class ProfileAvatarService {
  ProfileAvatarService(this._client);

  static const _bucket = 'profile-avatars';
  final SupabaseClient _client;

  Future<UserAvatarProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserAvatarProfile.fromJson(row);
  }

  Future<UserAvatarProfile> setPresetAvatar({
    required String userId,
    required String assetPath,
  }) async {
    final data = {
      'user_id': userId,
      'avatar_mode': ProfileAvatarMode.preset.name,
      'avatar_asset_path': assetPath,
      'avatar_storage_path': null,
      'avatar_url': null,
    };
    await _client.from('profiles').upsert(data);
    return UserAvatarProfile.fromJson(data);
  }

  Future<UserAvatarProfile> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) async {
    final key = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          key,
          bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    final url = _client.storage.from(_bucket).getPublicUrl(key);
    final data = {
      'user_id': userId,
      'avatar_mode': ProfileAvatarMode.upload.name,
      'avatar_asset_path': null,
      'avatar_storage_path': key,
      'avatar_url': url,
    };
    await _client.from('profiles').upsert(data);
    return UserAvatarProfile.fromJson(data);
  }

  Future<UserAvatarProfile> clearAvatar({required String userId}) async {
    final data = {
      'user_id': userId,
      'avatar_mode': ProfileAvatarMode.none.name,
      'avatar_asset_path': null,
      'avatar_storage_path': null,
      'avatar_url': null,
    };
    await _client.from('profiles').upsert(data);
    return UserAvatarProfile.fromJson(data);
  }
}

final imagePickerProvider = Provider<ImagePicker>((_) => ImagePicker());
final profileAvatarServiceProvider = Provider<ProfileAvatarService>((ref) {
  return ProfileAvatarService(ref.watch(supabaseClientProvider));
});
