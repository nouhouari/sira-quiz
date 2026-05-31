import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/db/seed/seeder.dart';
import 'data/repositories/quiz_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open ONE database instance, seed it, then hand it to Riverpod.
  // Do NOT close it here — the app owns it for its entire lifetime.
  final db = AppDatabase();
  await DatabaseSeeder(db).seedIfNeeded();

  runApp(
    ProviderScope(
      overrides: [
        // Pass the already-opened (and seeded) DB into the provider graph
        // so the rest of the app shares the same connection.
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const SiraQuizApp(),
    ),
  );
}
