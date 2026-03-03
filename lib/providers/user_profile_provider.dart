import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/providers/auth_provider.dart';

class UserProfileMeta {
  const UserProfileMeta({
    required this.name,
    required this.age,
    required this.gender,
  });

  final String name;
  final int? age;
  final String gender;

  bool get isComplete =>
      name.trim().isNotEmpty &&
      age != null &&
      age! >= 13 &&
      age! <= 120 &&
      (gender == 'male' || gender == 'female' || gender == 'na');

  List<String> get missingFields {
    final fields = <String>[];
    if (name.trim().isEmpty) fields.add('name');
    if (age == null || age! < 13 || age! > 120) fields.add('age');
    if (!(gender == 'male' || gender == 'female' || gender == 'na')) {
      fields.add('gender');
    }
    return fields;
  }

  factory UserProfileMeta.fromUser(User? user) {
    final data = user?.userMetadata ?? const <String, dynamic>{};
    final ageRaw = data['age'];
    final parsedAge = ageRaw is int
        ? ageRaw
        : (ageRaw is String ? int.tryParse(ageRaw) : null);
    return UserProfileMeta(
      name: (data['name'] as String? ?? '').trim(),
      age: parsedAge,
      gender: (data['gender'] as String? ?? '').toLowerCase(),
    );
  }
}

final userProfileMetaProvider = Provider<UserProfileMeta>((ref) {
  final user = ref.watch(currentUserProvider);
  return UserProfileMeta.fromUser(user);
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  return ref.watch(userProfileMetaProvider).isComplete;
});

final missingProfileFieldsProvider = Provider<List<String>>((ref) {
  return ref.watch(userProfileMetaProvider).missingFields;
});
