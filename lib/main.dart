import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/story_buddy_screen.dart';

void main() {
  runApp(const ProviderScope(child: PebloStoryBuddyApp()));
}

/// Root widget for the Peblo Smart Story Buddy application.
class PebloStoryBuddyApp extends StatelessWidget {
  const PebloStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peblo Smart Story Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const StoryBuddyScreen(),
    );
  }
}
