import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the current active tab index for the MainNavigationScreen
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Tracks whether the notifications screen is in selection mode so we can hide
// the floating nav while bulk actions are active.
final notificationSelectionModeProvider = StateProvider<bool>((ref) => false);
