import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/avatar_presets.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';
import 'package:winkidoo/services/profile_avatar_service.dart';

class ProfileCompletionSheet extends ConsumerStatefulWidget {
  const ProfileCompletionSheet({super.key});

  @override
  ConsumerState<ProfileCompletionSheet> createState() =>
      _ProfileCompletionSheetState();
}

class _ProfileCompletionSheetState
    extends ConsumerState<ProfileCompletionSheet> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _gender = 'na';
  bool _saving = false;
  String? _selectedPreset;
  Uint8List? _pickedAvatarBytes;

  @override
  void initState() {
    super.initState();
    final meta = ref.read(userProfileMetaProvider);
    _nameController.text = meta.name;
    _ageController.text = meta.age?.toString() ?? '';
    _gender = (meta.gender == 'male' ||
            meta.gender == 'female' ||
            meta.gender == 'na')
        ? meta.gender
        : 'na';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final age = int.parse(_ageController.text.trim());
      final merged = Map<String, dynamic>.from(user.userMetadata ?? const {});
      merged['name'] = _nameController.text.trim();
      merged['age'] = age;
      merged['gender'] = _gender;

      await Supabase.instance.client.auth
          .updateUser(UserAttributes(data: merged));
      if (_pickedAvatarBytes != null) {
        await ref.read(profileAvatarServiceProvider).uploadAvatar(
              userId: user.id,
              bytes: _pickedAvatarBytes!,
            );
      } else if (_selectedPreset != null) {
        await ref.read(profileAvatarServiceProvider).setPresetAvatar(
              userId: user.id,
              assetPath: _selectedPreset!,
            );
      }
      ref.invalidate(userAvatarProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile details. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewPath = _selectedPreset;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete your game profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your name, age, and gender before creating or joining battles.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
              validator: (value) {
                final age = int.tryParse((value ?? '').trim());
                if (age == null) return 'Enter a valid age';
                if (age < 13 || age > 120) {
                  return 'Age must be between 13 and 120';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'na', child: Text('Prefer not to say')),
              ],
              onChanged: (value) => setState(() => _gender = value ?? 'na'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final file = await ref
                                .read(imagePickerProvider)
                                .pickImage(source: ImageSource.gallery);
                            if (file == null) return;
                            final bytes = await file.readAsBytes();
                            if (!mounted) return;
                            setState(() {
                              _pickedAvatarBytes = bytes;
                              _selectedPreset = null;
                            });
                          },
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Upload photo'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_pickedAvatarBytes != null || _selectedPreset != null)
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _pickedAvatarBytes = null;
                              _selectedPreset = null;
                            }),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kAvatarPresetAssets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final asset = kAvatarPresetAssets[i];
                  final selected = _selectedPreset == asset;
                  return GestureDetector(
                    onTap: _saving
                        ? null
                        : () => setState(() {
                              _selectedPreset = asset;
                              _pickedAvatarBytes = null;
                            }),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryPink
                              : Colors.white.withValues(alpha: 0.26),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_pickedAvatarBytes != null || previewPath != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickedAvatarBytes != null
                        ? Image.memory(_pickedAvatarBytes!, fit: BoxFit.cover)
                        : Image.asset(previewPath!, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Avatar selected',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save and continue'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> ensureProfileComplete(BuildContext context, WidgetRef ref) async {
  if (ref.read(isProfileCompleteProvider)) return true;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ProfileCompletionSheet(),
  );
  return result == true;
}
