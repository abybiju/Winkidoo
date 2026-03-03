import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';

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
                if (value == null || value.trim().isEmpty)
                  return 'Enter your name';
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
                if (age < 13 || age > 120)
                  return 'Age must be between 13 and 120';
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
