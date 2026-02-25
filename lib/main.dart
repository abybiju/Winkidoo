import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No defaults in repo — pass keys via --dart-define to avoid committing secrets
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(
    const ProviderScope(
      child: WinkidooApp(),
    ),
  );
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Missing Supabase configuration.\n\n'
              'Run with:\n'
              'flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
